`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.02.2025 11:45:33
// Design Name: 
// Module Name: top_design
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


module top_design(
    output MISO,
    input MOSI,
    input spi_clk,
    input chip_select_n,
    input clk,
    input reset_n_in,
    output done_int,
    output data_valid,
    output reset_led,
    output clk_out
    );
    
parameter 
WIDTH_WGT = 8,
DATA_WIDTH = 8,
PSUM_WIDTH = 32,
N_PEs = 16,
N_PEsby4 = 4,
BIAS_WIDTH= 16,
ALPHA_WIDTH = 16,
BETA_WIDTH = 8,

WIDTH_ADDR_ACT = 12, 
WIDTH_ACT_MEM = 8, 
DEPTH_ACT_MEM = 3000,
ACT_MEM_HEADER = 8'b10,

WIDTH_ADDR_PARAM = 15, 
WIDTH_PARAM_MEM = 128,
DEPTH_PARAM_MEM = 25500,
PARAM_MEM_HEADER = 8'b01,

WIDTH_ADDR_INST = 6,
WIDTH_INST_MEM = 80, 
DEPTH_INST_MEM = 64,
INST_MEM_HEADER = 8'b11,
 
WIDTH_SPI_WORD = 8,
SPI_OUT_ADDRESS_SIZE = 4,
SPI_IN_ADDRESS_SIZE = 4,
SPI_OUT_ADDRESS_DEPTH = 16,

WGT_TILE_WIDTH = 8;

wire        reset_n;
//assign reset_n = reset_n_in;
assign reset_n = !(proc_reset || !reset_n_in);

assign clk_out = clk;

reg [1:0]   set_reg = 2'b00;

wire [WIDTH_ACT_MEM-1:0] actmem_in_ext;
wire [WIDTH_PARAM_MEM-1:0] parammem_in_ext;
wire [WIDTH_INST_MEM-1:0] instmem_in_ext;
wire [WIDTH_ADDR_ACT-1:0] addr_actmem_ext;
wire [WIDTH_ADDR_PARAM-1:0] addr_parammem_ext;
wire [WIDTH_ADDR_INST-1:0] addr_instmem_ext;

wire [WIDTH_ACT_MEM-1:0] actmem_out;
wire [WIDTH_ADDR_ACT-1:0]addr_actmem_int;
wire [WIDTH_ACT_MEM-1:0]actmem_in_int;
wire [WIDTH_ADDR_INST-1:0] addr_instmem_int;

assign reset_led = reset_n;

    
processor_top #(
    .WIDTH_WGT(WIDTH_WGT),
    .DATA_WIDTH(DATA_WIDTH),
    .PSUM_WIDTH(PSUM_WIDTH),
    
    .N_PEs(N_PEs),
    .N_PEsby4(N_PEsby4),
    
    .BIAS_WIDTH(BIAS_WIDTH),
    .ALPHA_WIDTH(ALPHA_WIDTH),
    .BETA_WIDTH(BETA_WIDTH),
    
    .WIDTH_ACT_MEM(WIDTH_ACT_MEM),
    .DEPTH_ACT_MEM(DEPTH_ACT_MEM),
    .WIDTH_ADDR_ACT(WIDTH_ADDR_ACT),
    
    
    .WIDTH_PARAM_MEM(WIDTH_PARAM_MEM),
    .DEPTH_PARAM_MEM(DEPTH_PARAM_MEM),
    .WIDTH_ADDR_PARAM(WIDTH_ADDR_PARAM),
    
    .WIDTH_INST_MEM(WIDTH_INST_MEM),
    .DEPTH_INST_MEM(DEPTH_INST_MEM),
    .WIDTH_ADDR_INST(WIDTH_ADDR_INST),
    
    .WGT_TILE_WIDTH(WGT_TILE_WIDTH)
    
) 
processor_0 (
    .clk(clk),
    .resetn(reset_n),
    .en(enable),
    .sel_ext(sel_ext),
    
    .wea_instmem_ext(wea_instmem_ext),
    .addr_instmem_ext(addr_instmem_ext),
    .instmem_in_ext(instmem_in_ext),
    .addr_instmem_int(addr_instmem_int),
    
    .wea_parammem_ext(wea_parammem_ext),
    .addr_parammem_ext(addr_parammem_ext),
    .parammem_in_ext(parammem_in_ext),
    
    .wea_actmem_ext(wea_actmem_ext),
    .addr_actmem_ext(addr_actmem_ext),
    .actmem_in_ext(actmem_in_ext),
    .actmem_out(actmem_out),
    .addr_actmem_int(addr_actmem_int),
    .actmem_in_int(actmem_in_int),
    .wea_actmem_int(wea_actmem_int),
    
    .done(done_int),
    .done_layer(done_layer)
);

spi_top #(
    .WIDTH_ADDR_ACT(WIDTH_ADDR_ACT), 
    .WIDTH_ACT_MEM(WIDTH_ACT_MEM), 
    .ACT_MEM_HEADER(ACT_MEM_HEADER),
    
    .WIDTH_ADDR_PARAM(WIDTH_ADDR_PARAM), 
    .WIDTH_PARAM_MEM(WIDTH_PARAM_MEM),
    .PARAM_MEM_HEADER(PARAM_MEM_HEADER),

    .WIDTH_ADDR_INST(WIDTH_ADDR_INST),
    .WIDTH_INST_MEM(WIDTH_INST_MEM), 
    .INST_MEM_HEADER(INST_MEM_HEADER),
     
    .WIDTH_SPI_WORD(WIDTH_SPI_WORD),
    .SPI_OUT_ADDRESS_SIZE(SPI_OUT_ADDRESS_SIZE),
    .SPI_IN_ADDRESS_SIZE(SPI_IN_ADDRESS_SIZE),
    .SPI_OUT_ADDRESS_DEPTH(SPI_OUT_ADDRESS_DEPTH)
)
spi_0 (

    .reset_n(reset_n_in),
    .clk(clk),

    .spi_clk(spi_clk),
    .MOSI(MOSI),
    .MISO(MISO),
    .chip_select_n(chip_select_n),
    .set_reg(set_reg),

    .act_mem_addr(addr_actmem_ext),
    .act_mem_data(actmem_in_ext),
    .act_mem_wren(wea_actmem_ext),
    .act_mem_q(actmem_out),
    .data_ready(data_valid),
    .sel_ext(sel_ext),

    .param_mem_addr(addr_parammem_ext),
    .param_mem_data(parammem_in_ext),
    .param_mem_wren(wea_parammem_ext),

    .inst_mem_addr(addr_instmem_ext),
    .inst_mem_data(instmem_in_ext),
    .inst_mem_wren(wea_instmem_ext),

    .proc_enable(enable),
    .proc_reset(proc_reset)
);
endmodule
