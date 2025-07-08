`timescale 1ns / 1ps
module processor_TB (

);

integer               data_file    ; // file handler
integer               scan_file    ; // file handler
integer               scan_file2   ; // file handler
integer               out_file     ; // file handler
integer               actual_file  ; // file handler
integer               test_file    ; // file handler
logic signed [7:0] captured_data;
logic signed [7:0] captured_data2;
`define NULL 0

reg clk = 1'b0;
always #1 clk <= ~clk;

reg reset_n = 1'b1;

reg         spi_clk = 1'b0;
reg         MOSI = 1'b0;
reg         chip_select_n = 1'b1;
wire        MISO;
wire        data_valid;
wire        done_int;

reg         dummy;

reg [7:0]   reset_cmd = 8'b00001101;
reg [7:0]   enable_cmd = 8'b00001110;
reg [7:0]   disable_cmd = 8'b00001100;

reg [2:0]   dwait = 1'b0;

reg [7:0]   outputReg;

integer index = 0;
integer line_num = 0;

bit mismatch_found = 0;

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
    output reg [7:0]  outReg
    //output      MOSI,
    //output      chip_select_n,
    //output      spi_clk
);
    begin
        #65 spi_clk <= 1'b0;
        MOSI <= serial_reg[7];
        outReg[7] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[6];
        outReg[6] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[5];
        outReg[5] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[4];
        outReg[4] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[3];
        outReg[3] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[2];
        outReg[2] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[1];
        outReg[1] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;

        MOSI <= serial_reg[0];
        outReg[0] <= MISO;
        #65 spi_clk <= 1'b1;
        #65 spi_clk <= 1'b0;
    end

endtask


initial begin
  // Make sure processor is reset
  $display("Step 1: Resetting Processor");
  #10 reset_n <= 1'b0;
  #10 reset_n <= 1'b1;

  // Make sure processor is disabled
  $display("Step 2: Disabling Processor");
  chip_select_n <= 1'b0;
  #200
  serialise_byte(disable_cmd, outputReg);
  chip_select_n <= 1'b1;
  
  // Transmit Instruction Information
  $display("Step 3: Transferring Instruction Data");
  data_file = $fopen("../data/instructionSPI.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end

  chip_select_n <= 1'b0;
  #200
  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, outputReg);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");

  // Transmit Parameter Information
  $display("Step 4: Transferring Parameter Data");
  data_file = $fopen("../data/parameterSPI.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end

  chip_select_n <= 1'b0;
  #200
  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, outputReg);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");

  // Transmit Activation Information
  $display("Step 5: Transferring Activation Data");
  data_file = $fopen("../data/activationSPI.txt", "r");
  if (data_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end

  chip_select_n <= 1'b0;
  #200
  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, outputReg);
      //use captured_data as you would any other wire or reg value;
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");
  
  // Reset Processor Registers
  $display("Step 6: Resetting Processor");
  #200 chip_select_n <= 1'b0;
  #200
  serialise_byte(reset_cmd, outputReg);
  #200 chip_select_n <= 1'b1;
  
  // Enable Processor
  $display("Step 7: Enabling Processor");
  #200 chip_select_n <= 1'b0;
  #200
  serialise_byte(enable_cmd, outputReg);
  #200 chip_select_n <= 1'b1;
  
  // Do Nothing Until Done is active
  $display("Step 8: Wait For Done Signal");
  while (!done_int) begin
    #10 dummy <= 1'b0;
  end
  //#12 enable <= 1'b0;
  
  // Update this to read back entire activation memory contents and then compare against expected output data
  $display("Step 9: Read Output Data");
  data_file = $fopen("../data/Memory_Readback.txt", "r");
  if (data_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end

  out_file=$fopen("../data/outData.txt", "w");
  if (out_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end
  
  chip_select_n <= 1'b0;
  #200
  while (!$feof(data_file)) begin
    scan_file = $fscanf(data_file, "%b\n", captured_data); 
    
    //$display("%b",captured_data);
    serialise_byte(captured_data, outputReg);
    if (dwait >= 5) begin
      $fdisplay(out_file, "%h",outputReg);
    end
    else begin
      dwait <= dwait + 1;
    end
  end
  #20 chip_select_n <= 1'b1;
  #100 $display("File Finished");
  // Enable Processor
  #200 chip_select_n <= 1'b0;
  #200
  serialise_byte(disable_cmd, outputReg);
  #200 chip_select_n <= 1'b1;
  // Reset Processor Registers
  #200 chip_select_n <= 1'b0;
  #200
  serialise_byte(reset_cmd, outputReg);
  #200 chip_select_n <= 1'b1;

  #1000

  $display("Step 10: Verify Output File");
  actual_file = $fopen("../data/14052025_output_data.txt", "r");
  if (data_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end

  test_file=$fopen("../data/outData.txt", "r");
  if (out_file == `NULL) begin
    //$display("data_file handle was NULL");
    $finish;
  end
  

while (!$feof(actual_file) && !$feof(test_file) && line_num < 4096) begin
    scan_file  = $fscanf(actual_file, "%h\n", captured_data); 
    scan_file2 = $fscanf(test_file,   "%h\n", captured_data2);
    line_num++;

    if (captured_data !== captured_data2) begin
        mismatch_found = 1;
        $display("Mismatch at line %0d: ACTUAL = %h, OBTAINED = %h", line_num, captured_data, captured_data2);
    end
end

if (mismatch_found) begin
    $display("RTL Output Mismatch with True Output");
end else begin
    $display("RTL Output Matches with True Output");
end

  //$display("Simulation Results Match Expected Software Results");
  $finish;
end


endmodule