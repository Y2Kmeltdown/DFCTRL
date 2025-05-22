`timescale 1ns / 1ps
module processor_TB (

);

integer               data_file    ; // file handler
integer               scan_file    ; // file handler
logic signed [7:0] captured_data;
`define NULL 0

reg clk = 1'b0;
always #5  clk <= ~clk;

reg reset_n = 1'b1;

reg         spi_clk = 1'b0;
reg         MOSI = 1'b0;
reg         chip_select_n = 1'b1;
reg         enable;
wire        MISO;
wire        data_valid;
wire        done_int;

reg         dummy;

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
    .DEPTH_ACT_MEM(4096),
    .ACT_MEM_HEADER(2'b10),
    
    .WIDTH_ADDR_PARAM(13), 
    .WIDTH_PARAM_MEM(128),
    .DEPTH_PARAM_MEM(7000),
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
    .spi_clk(spi_clk),
    .chip_select_n(chip_select_n),
    .clk(clk),
    .reset_n_in(reset_n),
    .done_int(done_int),
    .data_valid(data_valid),
    .reset_led(),
    .clk_out()
);


task serialise_byte(
    input [7:0] serial_reg,
    input       isStream
    //output      MOSI,
    //output      chip_select_n,
    //output      spi_clk
);
    begin
        chip_select_n <= 1'b0;

        MOSI <= serial_reg[7];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[6];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[5];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[4];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[3];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[2];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[1];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[0];
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        if (!isStream) begin
            #65 chip_select_n <= 1'b1;
        end

    end

endtask


initial begin
  #10 reset_n <= 1'b0;
  #10 reset_n <= 1'b1;
  #10 enable <= 1'b0;
  data_file = $fopen("data/15052025_instruction_data.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end

  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, 1);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");

  data_file = $fopen("data/15052025_parameter_data.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end

  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, 1);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");

  data_file = $fopen("data/15052025_activation_data.txt", "r");
  if (data_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end

  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, 1);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");
  
  #10 reset_n <= 1'b0;
  #10 reset_n <= 1'b1;
  #10 enable <= 1'b1;

  while (!done_int) begin
    #10 dummy <= 1'b0;
  end
  //#12 enable <= 1'b0;
  
  // Update this to read back entire activation memory contents and then compare against expected output data

  data_file = $fopen("D:/WSU_Research/RL Drone/Backup/Damien/Software/Data/activation_read_SPI.txt", "r");
  if (data_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end

  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, 1);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");

  #1000
  $finish;
end




endmodule