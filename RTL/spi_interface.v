`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 26.12.2024 16:32:58
// Design Name: 
// Module Name: spi_interface
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

module spi_interface (
    input wire clk,                 // System clock
    input wire rst_n,               // Active-low reset
    input wire spi_clk_data,        // SPI clock for data
    input wire spi_mosi_data,       // SPI Master-Out Slave-In for data
    output reg spi_miso_data,       // SPI Master-In Slave-Out for data
    input wire spi_clk_addr,        // SPI clock for address
    input wire spi_mosi_addr,       // SPI Master-Out Slave-In for address
    output reg spi_miso_addr,       // SPI Master-In Slave-Out for address
    input wire [2:0] cs             // Chip select for the three memories
);

    reg [7:0] spi_data_in;          // Data buffer for SPI input (data)
    reg [9:0] spi_addr_in;          // Address buffer for SPI input (address)
    reg [7:0] command;              // Command register
    reg [127:0] read_buffer;        // Buffer for memory read data
    reg [6:0] bit_count_data;       // Bit counter for SPI data
    reg [6:0] bit_count_addr;       // Bit counter for SPI address

    // Instantiate the memories with a depth of 1024
    reg [7:0] mem_8bit [0:1023];    // 8-bit memory
    reg [79:0] mem_80bit [0:1023];  // 80-bit memory
    reg [127:0] mem_128bit [0:1023]; // 128-bit memory

    // Temporary buffers for 80-bit and 128-bit data
    reg [79:0] temp_80bit_data;
    reg [127:0] temp_128bit_data;

    // SPI Data Reception Logic (Data Port)
    always @(posedge spi_clk_data or negedge rst_n) begin
        if (!rst_n) begin
            spi_data_in <= 8'b0;
            bit_count_data <= 0;
        end else begin
            spi_data_in <= {spi_data_in[6:0], spi_mosi_data};
            bit_count_data <= bit_count_data + 1;
        end
    end

    // SPI Data Reception Logic (Address Port)
    always @(posedge spi_clk_addr or negedge rst_n) begin
        if (!rst_n) begin
            spi_addr_in <= 10'b0;
            bit_count_addr <= 0;
        end else begin
            spi_addr_in <= {spi_addr_in[8:0], spi_mosi_addr};
            bit_count_addr <= bit_count_addr + 1;
        end
    end

    // Command Decoding and Memory Write/Read Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            command <= 8'b0;
            read_buffer <= 128'b0;
            temp_80bit_data <= 80'b0;
            temp_128bit_data <= 128'b0;
        end else if (bit_count_data == 8) begin
            command <= spi_data_in; // First 8 bits from data SPI are the command
        end else if (command[7:4] == 4'b0001) begin // Write operation
            if (cs[0]) begin
                mem_8bit[spi_addr_in] <= spi_data_in; // Write to 8-bit memory
            end else if (cs[1]) begin
                // Collect data for 80-bit memory
                temp_80bit_data <= {temp_80bit_data[71:0], spi_data_in};
                if (bit_count_data == 80) begin // Write once all 80 bits are received
                    mem_80bit[spi_addr_in] <= temp_80bit_data;
                end
            end else if (cs[2]) begin
                // Collect data for 128-bit memory
                temp_128bit_data <= {temp_128bit_data[119:0], spi_data_in};
                if (bit_count_data == 128) begin // Write once all 128 bits are received
                    mem_128bit[spi_addr_in] <= temp_128bit_data;
                end
            end
        end else if (command[7:4] == 4'b0010) begin // Read operation
            if (cs[0]) begin
                read_buffer <= {120'b0, mem_8bit[spi_addr_in]};  // Align 8-bit memory for read
            end else if (cs[1]) begin
                read_buffer <= {48'b0, mem_80bit[spi_addr_in]}; // Align 80-bit memory for read
            end else if (cs[2]) begin
                read_buffer <= mem_128bit[spi_addr_in];         // Full 128-bit memory
            end
        end
    end

    // SPI MISO Logic (Data Port)
    always @(posedge spi_clk_data or negedge rst_n) begin
        if (!rst_n) begin
            spi_miso_data <= 1'b0;
        end else if (command[7:4] == 4'b0010) begin // Read operation
            spi_miso_data <= read_buffer[127]; // Output MSB of the buffer
            read_buffer <= {read_buffer[126:0], 1'b0}; // Shift left for next bit
        end else begin
            spi_miso_data <= 1'b0; // Default to 0 when not reading
        end
    end

    // SPI MISO Logic (Address Port)
    always @(posedge spi_clk_addr or negedge rst_n) begin
        if (!rst_n) begin
            spi_miso_addr <= 1'b0;
        end else begin
            spi_miso_addr <= 1'b0; // Not used for address in this design
        end
    end

endmodule

