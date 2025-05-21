`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 19.09.2024 23:32:03
// Design Name: 
// Module Name: pe_array
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


module pe_array#(parameter WIDTH_WGT = 8, DATA_WIDTH = 8, PSUM_WIDTH = 32, N_PEs = 16, BIAS_WIDTH = 16)(
    input clk, 
    input reset,rst_pe_relu_reg,
    input [N_PEs-1:0] wea_reg1,wea_reg2, 
    input shift,load_bias,load_psum,sel_pe_reg,
    input ia_sign,if_relu,
    input [DATA_WIDTH-1:0] ia, 
    input [WIDTH_WGT*N_PEs-1:0] wgt, 
    input [BIAS_WIDTH*N_PEs-1:0] bias,

    output [PSUM_WIDTH-1:0] psum_out
);

genvar i;    

wire [PSUM_WIDTH-1:0] pkt_x[N_PEs:0];

assign pkt_x[0] = {PSUM_WIDTH{1'b0}};   
assign psum_out = pkt_x[N_PEs];  

generate 
    for (i = 0; i < N_PEs; i = i + 1) begin: gl
        pe#(
            .WIDTH_WGT(WIDTH_WGT), 
            .DATA_WIDTH(DATA_WIDTH), 
            .PSUM_WIDTH(PSUM_WIDTH),
            .BIAS_WIDTH(BIAS_WIDTH)
        ) processing_element (
            .clk(clk),
            .reset(reset),
            .rst_pe_relu_reg(rst_pe_relu_reg),
            .wea_reg1(wea_reg1[i]),
            .wea_reg2(wea_reg2[i]),
            .gate_en(1'b1),
            .if_relu(if_relu),
            .shift(shift),
            .load_bias(load_bias),
            .load_psum(load_psum),
            .sel_pe_reg(sel_pe_reg),
            .ia_sign(ia_sign),
            .ia(ia),
            .wgt(wgt[WIDTH_WGT*(N_PEs-i)-1 : WIDTH_WGT*(N_PEs-i-1)]),
            .bias(bias[BIAS_WIDTH*(N_PEs-i)-1 : BIAS_WIDTH*(N_PEs-i-1)]),
            .psum_in(pkt_x[i]),
            .psum_out(pkt_x[i+1])
        );
    end
endgenerate

endmodule

