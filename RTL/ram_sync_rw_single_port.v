`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 20.09.2024 01:59:41
// Design Name: 
// Module Name: ram_sync_rw_single_port
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


module ram_sync_rw_single_port#(parameter MEM_WIDTH_DATA = 8, MEM_DEPTH = 256, WIDTH_MEM_ADDR = 8)(
    input clk, wea,
    input [MEM_WIDTH_DATA-1:0]data_in,
    input [WIDTH_MEM_ADDR-1:0]addr,

    output reg[MEM_WIDTH_DATA-1:0]data_out

);

    reg [MEM_WIDTH_DATA-1:0]mem[0:MEM_DEPTH-1];
    
//    initial
//    begin
//         $readmemb("D:/WSU_Research/RL Drone/Codes/Software/Data/param_mem_bin.txt", mem);
//    end 
     
    //**------READ FROM MEM-----**//

    always@(posedge clk)
    begin
        data_out <= mem[addr];
    end


    //**------WRITE TO MEM-----**//

    always @(posedge clk)
    begin
        if(wea)
            mem[addr] <= data_in;
    end

    

endmodule
