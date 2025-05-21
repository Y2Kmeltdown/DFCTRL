`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 19.09.2024 22:00:40
// Design Name: 
// Module Name: pe
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


module pe#(parameter WIDTH_WGT = 8, DATA_WIDTH = 8, PSUM_WIDTH = 32, BIAS_WIDTH = 16)(
    input clk, 
    input reset, rst_pe_relu_reg,
    input wea_reg1, wea_reg2, gate_en, if_relu,
    input shift, load_bias, load_psum, sel_pe_reg, 
    input ia_sign,
    input [DATA_WIDTH-1:0] ia,
    input [WIDTH_WGT-1:0] wgt,
    input [BIAS_WIDTH-1:0] bias,
    input [PSUM_WIDTH-1:0] psum_in,

    output [PSUM_WIDTH-1:0] psum_out
);

//**------WIRE DECLARATIONS-----**//

wire [DATA_WIDTH+WIDTH_WGT:0] mult_out;
wire [PSUM_WIDTH-1:0] mux_out1, mux_out2, mux_out3;
wire [DATA_WIDTH:0] ip1_mult;
wire [PSUM_WIDTH-1:0] add_out, add_out_relu;

//**------REG DECLARATIONS-----**//

reg [WIDTH_WGT-1:0] wgt_reg;
reg [DATA_WIDTH-1:0] ia_reg; 
reg [PSUM_WIDTH-1:0] psum_out1, psum_out2;

//**------COMBINATIONAL LOGIC-----**//

assign ip1_mult = ia_sign ? {ia_reg[DATA_WIDTH-1], ia_reg} : {1'b0, ia_reg};
assign mult_out = $signed(ip1_mult) * $signed(wgt_reg);
assign mux_out1 = load_psum ? psum_out2 : {{(PSUM_WIDTH-DATA_WIDTH-WIDTH_WGT-1){mult_out[DATA_WIDTH+WIDTH_WGT]}}, mult_out};
assign add_out = psum_out1 + mux_out1;
assign add_out_relu = (add_out[PSUM_WIDTH-1] & ~rst_pe_relu_reg & if_relu) ? 0 : add_out; //Change here
assign mux_out2 = shift ? psum_in : add_out_relu;
assign mux_out3 = load_bias ? {{(PSUM_WIDTH-BIAS_WIDTH){bias[BIAS_WIDTH-1]}}, bias} : mux_out2;
assign psum_out = sel_pe_reg ? psum_out2 : psum_out1;

//**------ACCUMULATION REGISTERS-----**//

always @(posedge clk or negedge reset) begin
    if (~reset)
        psum_out1 <= 0;
    else if (wea_reg1)
        psum_out1 <= mux_out3;
    else
        psum_out1 <= psum_out1;
end

always @(posedge clk or negedge reset) begin
    if (~reset)
        psum_out2 <= 0;
    else if (wea_reg2)
        psum_out2 <= mux_out3;
    else
        psum_out2 <= psum_out2;
end

//**------GATING REGISTERS TO REDUCE DYNAMIC POWER-----**//

always @(posedge clk or negedge reset) begin
    if (~reset)
    begin
        wgt_reg <= 0;
        ia_reg <= 0;
    end
    else if (gate_en)
    begin
        wgt_reg <= wgt;
        ia_reg <= ia;    
    end    
    else
    begin
        wgt_reg <= wgt_reg;
        ia_reg <= ia_reg; 
    end    
end

endmodule
