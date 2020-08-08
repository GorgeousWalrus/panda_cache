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
// Module name: cache_line
// 
// Functionality: cache line
//
// ------------------------------------------------------------

module cache_line#(
    parameter N_WORDS_PER_LINE = 8,
    parameter TAG_SIZE
)(
    input logic                             clk,
    input logic                             rstn_i,
    input logic                             repl_i,
    input logic                             we_i,
    input logic [N_WORDS_PER_LINE*32-1:0]   line_i,
    input logic [31:0]                      addr_i,
    output logic [N_WORDS_PER_LINE*32-1:0]  line_o,
    output logic [TAG_SIZE-1:0]             tag_o,
    output logic                            dirty_o,
    output logic                            valid_o
);

struct packed {
    logic [N_WORDS_PER_LINE*32-1:0] line;
    logic [TAG_SIZE-1:0]            tag;
    logic                           valid;
    logic                           dirty;
} line_n, line_q;

assign line_o = line_q.line;
assign tag_o = line_q.tag;
assign valid_o = line_q.valid;
assign dirty_o = line_q.dirty;

always_comb
begin
    line_n = line_q;

    if(we_i) begin
        line_n.line = line_i;
        if(line_q.valid && !repl_i) // we write into a valid cacheline -> dirty
            line_n.dirty = 1'b1;
        else begin // cacheline was invalid or being replaced -> valid
            line_n.valid = 1'b1;
            line_n.tag   = addr_i[31:32-TAG_SIZE];
        end
    end
end

always_ff @(posedge clk, negedge rstn_i)
begin
    if(!rstn_i) begin
        line_q <= 'b0;
    end else begin
        line_q <= line_n;
    end
    
end

endmodule