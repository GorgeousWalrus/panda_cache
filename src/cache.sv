// ------------------------ Disclaimer -----------------------
// No warranty of correctness, synthesizability or 
// functionality of this code is given.
// Use this code under your own risk.
// When using this code, copy this disclaimer at the top of 
// Your file
//
// (c) Luca Hanel 2020
//
// ------------------------------------------------------------
//
// Module name: cache
// 
// Functionality: Instruction cache prototype
//
// ------------------------------------------------------------

module cache #(
    parameter N_LINES = 8,
    parameter N_WORDS_PER_LINE = 8
)(
    input logic             clk,
    input logic             rstn_i,
    input logic             read_i,
    input logic             write_i,
    input logic [3:0]       we_i,
    input logic [31:0]      addr_i,
    input logic [31:0]      data_i,
    output logic [31:0]     data_o,
    output logic            valid_o,
    wb_bus_t.master         wb_bus
);

// LSU
logic           lsu_load;
logic           lsu_write;
logic [31:0]    lsu_addr;
logic [3:0]     lsu_we;
logic [31:0]    lu_data;
logic [31:0]    su_data;
logic           lsu_valid;

// Cacheline
logic [N_LINES-1:0]                             cl_repl;
logic [N_LINES-1:0]                             cl_we;
logic [N_WORDS_PER_LINE*32-1:0]                 cl_wline;
logic [N_LINES-1:0][N_WORDS_PER_LINE*32-1:0]    cl_rline;
logic [N_LINES-1:0][TAG_SIZE-1:0]               cl_tags;
logic [N_LINES-1:0]                             cl_dirty;
logic [N_LINES-1:0]                             cl_valid;

// Control and other
logic                               repl_req;
logic                               repl_valid;
logic                               incr_read_cnt;
logic [$clog2(N_LINES)-1:0]         valid_line;
logic [$clog2(N_LINES)-1:0]         repl_line;
logic [$clog2(N_WORDS_PER_LINE):0]  read_cnt;
logic [N_WORDS_PER_LINE*32-1:0]     cl_w;
logic [N_WORDS_PER_LINE*32-1:0]     cl_wrepl_n;
logic [N_WORDS_PER_LINE*32-1:0]     cl_wrepl_q;
logic                               wb_req_n;
logic                               wb_req_q;

localparam TAG_SIZE = 32-2-$clog2(N_WORDS_PER_LINE);

lsu lsu_i(
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .read_i     ( lsu_load  ),
    .write_i    ( lsu_write ),
    .we_i       ( lsu_we    ),
    .addr_i     ( lsu_addr  ),
    .data_i     ( su_data   ),
    .data_o     ( lu_data   ),
    .valid_o    ( lsu_valid ),
    .wb_bus     ( wb_bus    )
);

genvar ii;
for(ii = 0; ii < N_LINES; ii = ii + 1) begin : gen_cachelines
    cache_line #(
        .N_WORDS_PER_LINE( N_WORDS_PER_LINE ),
        .TAG_SIZE        ( TAG_SIZE         )
    ) cache_line_i(
        .clk        ( clk          ),
        .rstn_i     ( rstn_i       ),
        .repl_i     ( cl_repl[ii]  ),
        .we_i       ( cl_we[ii]    ),
        .addr_i     ( addr_i       ),
        .line_i     ( cl_wline     ),
        .line_o     ( cl_rline[ii] ),
        .tag_o      ( cl_tags[ii]  ),
        .dirty_o    ( cl_dirty[ii] ),
        .valid_o    ( cl_valid[ii] )
    );
end

// find correct line and decide wether to replace or not
always_comb
begin
    valid_line = 'b0;
    repl_req = 1'b0;

    if(read_i || write_i) begin
        repl_req = 1'b1;

        for(int i = 0; i < N_LINES; i = i + 1) begin
            if(cl_valid[i] && cl_tags[i] == addr_i[31:32-TAG_SIZE]) begin
                valid_line = i[$clog2(N_LINES)-1:0];
                repl_req = 1'b0;
            end
        end
    end
end

/* verilator lint_off WIDTH */
assign cl_w = (cl_rline[valid_line] & (~(512'hffffffff << 32*addr_i[$clog2(N_WORDS_PER_LINE)+1:2])));
/* verilator lint_on WIDTH */

always_comb
begin
    // Reading and writing to cachline (possiblie within one cycle)
    valid_o = 1'b0;
    cl_we = 'b0;
    cl_wline = 'b0;
    cl_repl = 'b0;


    if(!repl_req && (write_i || read_i)) begin
        valid_o = 1'b1;
        if(write_i) begin
            cl_we[valid_line] = 1'b1;
            /* verilator lint_off WIDTH */
            case(we_i)
                4'b1111:
                    cl_wline = cl_w | ({480'b0, data_i} << 32*(addr_i[$clog2(N_WORDS_PER_LINE)+1:2]));
                4'b0011:
                    cl_wline = cl_w | ({496'b0, data_i[15:0]} << 32*(addr_i[$clog2(N_WORDS_PER_LINE)+1:2]));
                4'b0001:
                    cl_wline = cl_w | ({504'b0, data_i[7:0]} << 32*(addr_i[$clog2(N_WORDS_PER_LINE)+1:2]));
                default:
                    cl_wline = cl_w | ({480'b0, data_i} << 32*(addr_i[$clog2(N_WORDS_PER_LINE)+1:2]));
            endcase
            /* verilator lint_on WIDTH */
        end else begin
            /* verilator lint_off WIDTH */
            data_o = cl_rline[valid_line] >> 32*(addr_i[$clog2(N_WORDS_PER_LINE)+1:2]);
            /* verilator lint_on WIDTH */
        end
    end else if(repl_req && repl_valid) begin
        cl_we[repl_line] = 1'b1;
        cl_repl[repl_line] = 1'b1;
        cl_wline = cl_wrepl_q;
    end
end

    // Writing back cacheline into storate and
    // reading new cachline from storage
always_comb
begin
    lsu_we = 'b0;
    lsu_load = 1'b0;
    lsu_write = 1'b0;
    repl_valid = 1'b0;
    incr_read_cnt = 1'b0;
    cl_wrepl_n = cl_wrepl_q;
    wb_req_n = wb_req_q;
    if(repl_req) begin
        if(cl_dirty[repl_line] && wb_req_q) begin
            lsu_write = 1'b1;
            lsu_we = 4'hf;
            lsu_addr = {cl_tags[repl_line], read_cnt[$clog2(N_WORDS_PER_LINE)-1:0], 2'b0};
            /* verilator lint_off WIDTH */
            su_data = cl_rline[repl_line] >> 32*(read_cnt[2:0]);
            /* verilator lint_on WIDTH */
            if(lsu_valid) begin
                incr_read_cnt = 1'b1;
                if(read_cnt == N_WORDS_PER_LINE)
                    wb_req_n = 1'b0;
            end
        end else begin
            lsu_load = 1'b1;
            lsu_addr = {addr_i[31:$clog2(N_WORDS_PER_LINE)+2], read_cnt[$clog2(N_WORDS_PER_LINE)-1:0], 2'b0};
            if(lsu_valid) begin
                /* verilator lint_off WIDTH */
                cl_wrepl_n = cl_wrepl_q | {480'b0, lu_data} << (32*read_cnt);
                /* verilator lint_on WIDTH */
                incr_read_cnt = 1'b1;
                if(read_cnt == N_WORDS_PER_LINE) begin
                    repl_valid = 1'b1;
                    wb_req_n = 1'b1;
                end
            end
        end
    end
end

always_ff @(posedge clk, negedge rstn_i)
begin
    if(!rstn_i) begin
        repl_line <= 'b0;
        cl_wrepl_q <= 'b0;
        read_cnt <= 'b0;
        wb_req_q <= 'b1;
    end else begin

        if(repl_valid) begin
            repl_line <= repl_line + 1;
        end

        wb_req_q <= wb_req_n;
        cl_wrepl_q <= 'b0;
        read_cnt <= 'b0;
        if(repl_req) begin
            cl_wrepl_q <= cl_wrepl_n;
            if(incr_read_cnt)
                read_cnt <= read_cnt + 1;
        end
    end
end


endmodule