`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 20.09.2024 01:10:57
// Design Name: 
// Module Name: post_processing
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


module post_processing #(parameter DATA_WIDTH = 8, PSUM_WIDTH = 32, ALPHA_WIDTH = 8, BETA_WIDTH = 4)(
    input clk,if_relu,
    input [PSUM_WIDTH-1:0] ppm_ip,
    input [BETA_WIDTH-1:0] beta,
    input [ALPHA_WIDTH-1:0] alpha,

    output [DATA_WIDTH-1:0] ppm_out
);

//**------WIRE DECLARATIONS-----**//

wire signed [PSUM_WIDTH+ALPHA_WIDTH-1:0] op1;
wire signed [PSUM_WIDTH+ALPHA_WIDTH-1:0] op_shift1;
wire pt5_bit1;
wire pos_bit1;
wire neg_bit1;
wire [DATA_WIDTH-1:0] clip1;
wire [DATA_WIDTH-1:0] sum;
wire [PSUM_WIDTH+ALPHA_WIDTH-1:0] op_mult1;

//**------REG DECLARATIONS-----**//

reg [DATA_WIDTH-1:0] clip1_reg;
reg pos_bit1_reg,neg_bit1_Reg;
reg pt5_bit1_reg;
reg [PSUM_WIDTH+ALPHA_WIDTH-1:0] op_mult1_reg;
reg [BETA_WIDTH-1:0] beta_reg,beta_reg_reg;
reg [ALPHA_WIDTH-1:0] alpha_reg;
reg ppm_ip_MSB;

assign op_mult1 = $signed({1'b0,alpha_reg}) * $signed(ppm_ip);

//**------PIPELINE REGISTERS-----**//
                
always @(posedge clk) begin
    op_mult1_reg <= op_mult1;
    beta_reg <= beta;
    beta_reg_reg <= beta_reg;
    alpha_reg <= alpha;
    ppm_ip_MSB <= ppm_ip[PSUM_WIDTH-1];
end

assign op1 = (ppm_ip_MSB & if_relu) ? 0 : op_mult1_reg; //RELU
assign op_shift1 = (beta_reg_reg <= 8'd255) ? op1 >>> (beta_reg_reg) : 0;

assign pt5_bit1 = (beta_reg_reg > 0) ? op1[beta_reg_reg-1] : 0;
assign pos_bit1 = ((($signed(op_shift1) >= $signed(32'd255)) & if_relu) | (($signed(op_shift1) >= $signed(32'd127)) & ~if_relu)) ? 1 : 0;
assign neg_bit1 = ((($signed(op_shift1) <= $signed(0)) & if_relu) | (($signed(op_shift1) <= $signed(-32'd128)) & ~if_relu)) ? 1 : 0;

assign clip1 = pos_bit1 ? (if_relu ? $signed(8'd255): $signed(32'd127)) : (neg_bit1 ? (if_relu ? $signed(0) :$signed(-32'd128)) : op_shift1);

//**------PIPELINE REGISTERS-----**//

always @(posedge clk) begin
    clip1_reg <= clip1;
    pos_bit1_reg <= pos_bit1;
    neg_bit1_Reg <= neg_bit1;
    pt5_bit1_reg <= pt5_bit1;
end

assign sum = (pt5_bit1_reg & ~pos_bit1_reg & if_relu) | (pt5_bit1_reg & ~pos_bit1_reg & ~neg_bit1_Reg & ~if_relu) ? clip1_reg + {{(7){1'b0}}, 1'b1} : clip1_reg;

assign ppm_out = {sum};

endmodule
