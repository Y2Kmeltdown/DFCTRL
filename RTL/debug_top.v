`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.03.2025 11:04:29
// Design Name: 
// Module Name: debug_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debug_top(
    input reset_n,
    output MISO,
    input MOSI,
    input SCK,
    input CS_N,
    output done_int,
	 output done_led,
    output data_valid,
    output reset_n_out,
    input clk_in,
    output clk_out
    );
	 

assign done_led = done_int;

assign reset_n_out = !reset_out;

top_design #(
    .WIDTH_WGT(8),
    .DATA_WIDTH(8),
    .PSUM_WIDTH(32),
    .N_PEs(16),
    .N_PEsby4(4),
    .BIAS_WIDTH(16),
    .ALPHA_WIDTH(16),
    .BETA_WIDTH(8),
    
    .WIDTH_ADDR_ACT(12), 
    .WIDTH_ACT_MEM(8), 
    .DEPTH_ACT_MEM(3000),
    .ACT_MEM_HEADER(2'b10),
    
    .WIDTH_ADDR_PARAM(15), 
    .WIDTH_PARAM_MEM(128),
    .DEPTH_PARAM_MEM(25500),
    .PARAM_MEM_HEADER(2'b01),
    
    .WIDTH_ADDR_INST(6),
    .WIDTH_INST_MEM(80), 
    .DEPTH_INST_MEM(64),
    .INST_MEM_HEADER(2'b11),
     
    .WIDTH_SPI_WORD(8),
    .SPI_OUT_ADDRESS_SIZE(4),
    .SPI_IN_ADDRESS_SIZE(4),
    .SPI_OUT_ADDRESS_DEPTH(16),
    
    .WGT_TILE_WIDTH(8)
) top_0 (
    .MISO(MISO),
    .MOSI(MOSI),
    .spi_clk(SCK),
    .chip_select_n(CS_N),
    .clk(clk_out),
    .reset_n_in(reset_n),
    .done_int(done_int),
    .data_valid(data_valid),
    .reset_led(reset_out),
    .clk_out()
);

PLL pll_0 (
		.refclk   (clk_in),   //  refclk.clk
		.rst      (!reset_n),      //   reset.reset
		.outclk_0 (clk_out), // outclk0.clk
		.locked   (locked)    //  locked.export
	);




endmodule
