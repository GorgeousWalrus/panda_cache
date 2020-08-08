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
// Module name: ram
// 
// Functionality: Single port ram
//
// ------------------------------------------------------------

module ram #(
    parameter SIZE = 1024
)(
    input logic           clk,
    input logic           rstn_i,
    input logic [31:0]    addr_i,
    input logic           en_i,
    input logic [3:0]     we_i,
    input logic [31:0]    din_i,
    output logic [31:0]   dout_o
);

logic [31:0]    addr;

(*ram_style = "block" *) reg [31:0] data[SIZE];

assign addr = $signed(addr_i >> 2);

initial
begin
    data[0]    = 32'd0;
    data[1]    = 32'd1;
    data[2]    = 32'd2;
    data[3]    = 32'd3;
    data[4]    = 32'd4;
    data[5]    = 32'd5;
    data[6]    = 32'd6;
    data[7]    = 32'd7;
    data[8]    = 32'd8;
    data[9]    = 32'd9;
    data[10]    = 32'd10;
    data[11]    = 32'd11;
    data[12]    = 32'd12;
    data[13]    = 32'd13;
    data[14]    = 32'd14;
    data[15]    = 32'd15;
    data[16]    = 32'd16;
    data[17]    = 32'd17;
    data[18]    = 32'd18;
    data[19]    = 32'd19;
    data[20]    = 32'd20;
    data[21]    = 32'd21;
    data[22]    = 32'd22;
    data[23]    = 32'd23;
    data[24]    = 32'd24;
    data[25]    = 32'd25;
    data[26]    = 32'd26;
    data[27]    = 32'd27;
    data[28]    = 32'd28;
    data[29]    = 32'd29;
    data[30]    = 32'd30;
    data[31]    = 32'd31;
    data[32]    = 32'd32;
    data[33]    = 32'd33;
    data[34]    = 32'd34;
    data[35]    = 32'd35;
    data[36]    = 32'd36;
    data[37]    = 32'd37;
    data[38]    = 32'd38;
    data[39]    = 32'd39;
end

always_comb
begin
    if(en_i) begin
        unique case(addr_i[1:0])
            2'b00 : dout_o = data[addr];
            2'b01 : dout_o = {data[addr][31:8] , data[addr+1][7:0] };
            2'b10 : dout_o = {data[addr][31:16], data[addr+1][15:0]};
            2'b11 : dout_o = {data[addr][31:24], data[addr+1][23:0]};
        endcase
    end
end

always_ff @(posedge clk, negedge rstn_i)
begin
    if(!rstn_i) begin
    end else begin
        if(en_i) begin
            case(we_i)
                4'b1111: begin
                    unique case(addr_i[1:0])
                        2'b00 : data[addr] <= din_i;
                        2'b01 : begin data[addr][31:8] <= din_i[23:0]; data[addr+1][7:0] <= din_i[31:24]; end
                        2'b10 : begin data[addr][31:16] <= din_i[15:0]; data[addr+1][15:0] <= din_i[31:16]; end
                        2'b11 : begin data[addr][31:24] <= din_i[7:0]; data[addr+1][23:0] <= din_i[31:8]; end
                    endcase
                end
                
                4'b0011: begin
                    unique case(addr_i[1:0])
                        2'b00 : data[addr][15:0] <= din_i[15:0];
                        2'b01 : begin data[addr][23:8] <= din_i[15:0]; end
                        2'b10 : begin data[addr][31:16] <= din_i[15:0]; end
                        2'b11 : begin data[addr][31:24] <= din_i[7:0]; data[addr+1][7:0] <= din_i[15:8]; end
                    endcase
                end
                
                4'b0001: begin
                    unique case(addr_i[1:0])
                        2'b00 : data[addr][7:0] <= din_i[7:0];
                        2'b01 : begin data[addr][15:8] <= din_i[7:0]; end
                        2'b10 : begin data[addr][23:16] <= din_i[7:0]; end
                        2'b11 : begin data[addr][31:24] <= din_i[7:0]; end
                    endcase
                end
                
                default: begin
                end
            endcase
        end
    end
end

endmodule