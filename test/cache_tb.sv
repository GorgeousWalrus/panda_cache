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
// Module name: wishbone_tb
// 
// Functionality: wishbone testbench
//
// ------------------------------------------------------------

`include "wb_intf.sv"

module cache_tb
(
    input logic          clk,
    input logic          rstn_i,
    output logic [31:0]  data_o,
    input logic [31:0]   data_i,
    input logic [31:0]   addr_i,
    input logic          read_i,
    input logic          write_i,
    output logic         valid_o
);
/* verilator lint_off PINMISSING */
/* verilator lint_off UNDRIVEN */

wb_bus_t#(.TAGSIZE(1)) wb_bus;

assign wb_bus.wb_gnt = 1'b1;

cache#(
) cache_i (
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .read_i     ( read_i    ),
    .write_i    ( write_i   ),
    .addr_i     ( addr_i    ),
    .data_i     ( data_i    ),
    .data_o     ( data_o    ),
    .valid_o    ( valid_o   ),
    .wb_bus     ( wb_bus    )
);

wb_ram_wrapper #(
  .SIZE (16384)
) ram_i (
  .clk    ( clk       ),
  .rstn_i ( rstn_i    ),
  .wb_bus ( wb_bus    )
);

endmodule