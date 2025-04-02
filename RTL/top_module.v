`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 20.09.2024 00:51:14
// Design Name: 
// Module Name: top_module
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

module processor_top#(parameter WIDTH_WGT = 8, DATA_WIDTH = 8, PSUM_WIDTH = 32, N_PEs = 16, N_PEsby4 = 4, BIAS_WIDTH= 16, ALPHA_WIDTH = 16, BETA_WIDTH = 8,
WIDTH_ACT_MEM = 8, WIDTH_PARAM_MEM = 128, WIDTH_INST_MEM = 80, DEPTH_ACT_MEM = 3000, DEPTH_PARAM_MEM = 25500, DEPTH_INST_MEM = 64, WIDTH_ADDR_ACT = 12, WIDTH_ADDR_PARAM = 15,
WIDTH_ADDR_INST = 6, WGT_TILE_WIDTH = 8)(
    input clk, 
    input resetn, 
    input en,
    input sel_ext,
    input wea_instmem_ext,wea_parammem_ext,wea_actmem_ext,
    input [WIDTH_ACT_MEM-1:0] actmem_in_ext,
    input [WIDTH_PARAM_MEM-1:0] parammem_in_ext,
    input [WIDTH_INST_MEM-1:0] instmem_in_ext,
    input [WIDTH_ADDR_ACT-1:0] addr_actmem_ext,
    input [WIDTH_ADDR_PARAM-1:0] addr_parammem_ext,
    input [WIDTH_ADDR_INST-1:0] addr_instmem_ext,
    
    output [WIDTH_ACT_MEM-1:0] actmem_out,
    output [WIDTH_ADDR_ACT-1:0]addr_actmem_int,
    output [WIDTH_ACT_MEM-1:0]actmem_in_int,
    output wea_actmem_int,
    output done,done_layer,
    output [WIDTH_ADDR_INST-1:0] addr_instmem_int
    
    );

//**------WIRE DECLARATIONS-----**//

wire shift,load_bias,load_psum,sel_pe_reg,ia_sign,rst_pe_reg,rst_pe_relu_reg,wea_actmem,wea_parammem,wea_instmem,rst_addr_instmem,en_addr_instmem,load_base_instmem,rst_addr_parammem,en_addr_parammem,load_base_parammem,rst_addr_actmem,en_addr_actmem,load_base_actmem;
wire [N_PEs-1:0]wea_reg1,wea_reg2;
wire [WIDTH_PARAM_MEM-1:0]parammem_out; 
wire [WIDTH_INST_MEM-1:0]instmem_out;
wire [WIDTH_ACT_MEM-1:0]actmem_in;
wire [WIDTH_ADDR_ACT-1:0]addr_actmem,base_addr_actmem,stride_actmem;
wire [WIDTH_ADDR_PARAM-1:0]addr_parammem,base_addr_parammem,stride_parammem,addr_parammem_int;
wire [WIDTH_ADDR_INST-1:0]addr_instmem,base_addr_instmem,stride_instmem;
wire [PSUM_WIDTH-1:0] psum_out;
wire [BIAS_WIDTH-1:0] bias;
wire [BETA_WIDTH-1:0] beta;
wire [ALPHA_WIDTH-1:0] alpha;
wire [1:0]sel_ppm_param; // Change later
wire [31:0] beta_alpha_bias; // Change later
    
assign addr_instmem = (sel_ext) ? addr_instmem_ext : addr_instmem_int;
assign wea_instmem = wea_instmem_ext;
assign addr_parammem = (sel_ext) ? addr_parammem_ext : addr_parammem_int;
assign wea_parammem = wea_parammem_ext;
assign addr_actmem = (sel_ext) ? addr_actmem_ext : addr_actmem_int;
assign wea_actmem = (sel_ext) ? wea_actmem_ext : wea_actmem_int;
assign actmem_in = sel_ext ? actmem_in_ext : actmem_in_int;

//**------TOP-LEVEL CONTROLLER-----**//

controller_top #(.WIDTH_INST_MEM(WIDTH_INST_MEM),.WIDTH_ADDR_INST(WIDTH_ADDR_INST),.WIDTH_ADDR_PARAM(WIDTH_ADDR_PARAM),.WIDTH_ADDR_ACT(WIDTH_ADDR_ACT),.WGT_TILE_WIDTH(WGT_TILE_WIDTH),.N_PEs(N_PEs),.N_PEsby4(N_PEsby4)) cntl_top (
.clk(clk),.resetn(resetn),.en(en),.inst(instmem_out),.base_addr_instmem_reg(base_addr_instmem),.stride_instmem_reg(stride_instmem),.rst_addr_instmem_reg(rst_addr_instmem),.en_addr_instmem_reg(en_addr_instmem),
.load_base_instmem_reg(load_base_instmem),.base_addr_actmem_reg(base_addr_actmem),.stride_actmem_reg(stride_actmem),.rst_addr_actmem_reg(rst_addr_actmem),.en_addr_actmem_reg(en_addr_actmem),.load_base_actmem_reg(load_base_actmem),
.wea_actmem_reg(wea_actmem_int),.base_addr_parammem_reg(base_addr_parammem),.stride_parammem_reg(stride_parammem),.rst_addr_parammem_reg(rst_addr_parammem),.en_addr_parammem_reg(en_addr_parammem),.load_base_parammem_reg(load_base_parammem),
.rst_pe_reg_reg(rst_pe_reg),.rst_pe_relu_reg_reg(rst_pe_relu_reg),.wea_reg_reg1(wea_reg1),.wea_reg_reg2(wea_reg2),.shift_reg(shift),.load_bias_reg(load_bias),.load_psum_reg(load_psum),.sel_pe_reg_reg(sel_pe_reg),.ia_sign_reg(ia_sign),.done_reg(done),.done_layer_reg(done_layer),.sel_ppm_param_present(sel_ppm_param));
    
//**------ACTIVATION MEMORY (SINGLE PORT) AND ADDR GENERATION-----**//

addr_gen #(.ADDR_WIDTH(WIDTH_ADDR_ACT)) agen_actmem (.clk(clk),.reset(rst_addr_actmem),.en(en_addr_actmem),.load_base(load_base_actmem),.base_addr(base_addr_actmem),.stride(stride_actmem),.addr_reg(addr_actmem_int));

//ram_sync_rw_single_port#(.MEM_WIDTH_DATA(WIDTH_ACT_MEM),.MEM_DEPTH(DEPTH_ACT_MEM),.WIDTH_MEM_ADDR(WIDTH_ADDR_ACT)) act_mem (.clk(clk),.wea(wea_actmem),.data_in(actmem_in),.addr(addr_actmem),.data_out(actmem_out));
activation_mem activation_memory (.clock(clk),.wren(wea_actmem),.data(actmem_in),.address(addr_actmem),.q(actmem_out));

//**------PARAMETER MEMORY (SINGLE PORT) AND ADDR GENERATION-----**//

addr_gen #(.ADDR_WIDTH(WIDTH_ADDR_PARAM)) agen_parammem (.clk(clk),.reset(rst_addr_parammem),.en(en_addr_parammem),.load_base(load_base_parammem),.base_addr(base_addr_parammem),.stride(stride_parammem),.addr_reg(addr_parammem_int));

//ram_sync_rw_single_port#(.MEM_WIDTH_DATA(WIDTH_PARAM_MEM),.MEM_DEPTH(DEPTH_PARAM_MEM),.WIDTH_MEM_ADDR(WIDTH_ADDR_PARAM)) param_mem (.clk(clk),.wea(wea_parammem),.data_in(parammem_in_ext),.addr(addr_parammem),.data_out(parammem_out));
parameter_mem parameter_memory (.clock(clk),.wren(wea_parammem),.data(parammem_in_ext),.address(addr_parammem),.q(parammem_out));

//**------INSTRUCTION MEMORY (SINGLE PORT) AND ADDR GENERATION-----**//

addr_gen #(.ADDR_WIDTH(WIDTH_ADDR_INST)) agen_instmem (.clk(clk),.reset(rst_addr_instmem),.en(en_addr_instmem),.load_base(load_base_instmem),.base_addr(base_addr_instmem),.stride(stride_instmem),.addr_reg(addr_instmem_int));

//ram_sync_rw_single_port#(.MEM_WIDTH_DATA(WIDTH_INST_MEM),.MEM_DEPTH(DEPTH_INST_MEM),.WIDTH_MEM_ADDR(WIDTH_ADDR_INST)) inst_mem (.clk(clk),.wea(wea_instmem),.data_in(instmem_in_ext),.addr(addr_instmem),.data_out(instmem_out));
instruction_mem instruction_memory (.clock(clk),.wren(wea_instmem),.data(instmem_in_ext),.address(addr_instmem),.q(instmem_out));

//**------PE ARRAY-----**//
    
pe_array#(.WIDTH_WGT(WIDTH_WGT),.DATA_WIDTH(DATA_WIDTH),.PSUM_WIDTH(PSUM_WIDTH),.N_PEs(N_PEs),.BIAS_WIDTH(BIAS_WIDTH)) processing_array (.clk(clk),.reset(rst_pe_reg),.rst_pe_relu_reg(rst_pe_relu_reg),.wea_reg1(wea_reg1),.wea_reg2(wea_reg2),
.shift(shift),.load_bias(load_bias),.load_psum(load_psum),.sel_pe_reg(sel_pe_reg),.ia_sign(ia_sign),.ia(actmem_out),.wgt(parammem_out),.bias({parammem_out,parammem_out}),.psum_out(psum_out));

//**------POST PROCESSING MODULE-----**//

assign alpha = parammem_out[ALPHA_WIDTH+BETA_WIDTH-1:BETA_WIDTH];
assign beta = parammem_out[BETA_WIDTH-1:0];

post_processing #(.DATA_WIDTH(DATA_WIDTH),.PSUM_WIDTH(PSUM_WIDTH),.ALPHA_WIDTH(ALPHA_WIDTH), 
.BETA_WIDTH(BETA_WIDTH)) ppm (.clk(clk),.ppm_ip(psum_out),.beta(beta),.alpha(alpha),.ppm_out(actmem_in_int));

endmodule
