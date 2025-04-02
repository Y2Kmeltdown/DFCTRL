`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.01.2022 21:58:41
// Design Name: 
// Module Name: addr_gen
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

module addr_gen #(parameter ADDR_WIDTH = 8)(
    input clk,reset,en,load_base,
    input [ADDR_WIDTH-1:0]base_addr,stride,

    output reg[ADDR_WIDTH-1:0]addr_reg
);

    wire [ADDR_WIDTH-1:0]addr,mux_out;

    assign mux_out = (load_base) ? base_addr : addr;
    assign addr = addr_reg + stride;

    always@(posedge clk or negedge reset)
    begin
        if (!reset)
            begin
                addr_reg <= 0;
            end
        else if(en)
        begin
            addr_reg <= mux_out;
        end
    end

endmodule



