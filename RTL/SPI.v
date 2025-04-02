module SPI #(
    parameter 
    SPI_BUS_WIDTH = 8
)
(
    input clk,
    input chip_select_n,
    input sub_clk,
    input sub_in,
    output sub_out,
    input   reset_n,
    output  reg     rd_req,
    output  reg     wr_req,

    input   [SPI_BUS_WIDTH-1:0]   internal_to_SPI_in,
    output  [SPI_BUS_WIDTH-1:0]   SPI_to_internal_out
);

synchronizer #(
    .Width(1),
	 .Stages(2)
) sck_sync ( 
    .clk  (clk),
    .reset  (!reset_n),
	 // Inputs:
    .in  (sub_clk),
    // Outputs:
    .out  (sub_clk_sync)
);

edge_detector #(
    .POSEDGE(1'b0)
) spi_negedge (
        // Inputs:
    .clk  (clk),
    .reset_n  (reset_n),
    .sig  (sub_clk_sync),
        // Outputs:
    .out  (),
    .sig_edge   (spiNEGEDGE)
);

edge_detector #(
    .POSEDGE(1'b1)
) spi_posedge (
        // Inputs:
    .clk  (clk),
    .reset_n  (reset_n),
    .sig  (sub_clk_sync),
        // Outputs:
    .out  (),
    .sig_edge   (spiPOSEDGE)
);



  
// Primary SPI shift Register
reg     [SPI_BUS_WIDTH-1:0]   shift_reg;

assign SPI_to_internal_out = shift_reg;

// Shift register output buffer to send data over SPI
assign sub_out = !chip_select_n ? shift_reg[SPI_BUS_WIDTH-1] : 1'bZ;

// Read and write counters to synchronise updating and reading the SPI shift register
reg     [2:0]   bit_cnt;

reg	  [7:0]	 pos_operator;
reg	  [7:0]	 neg_operator;

reg	  			 packet = 1'b0;

reg	  [7:0]	 sckIgnore = 1'b0;
reg				 sckReady = 1'b0;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        shift_reg <= 1'b0;
        wr_req <= 1'b0;
        rd_req <= 1'b0;
		  pos_operator <= 1'b0;
		  neg_operator <= 1'b0;
		  bit_cnt <= 1'b0;
		  packet <= 1'b0;
		  sckIgnore <= 1'b0;
		  sckReady <= 1'b0;
		  
    end
    else begin
			if (!chip_select_n) begin
			
				if (!sckReady) begin
					sckIgnore <= sckIgnore + 1;
					if (sckIgnore >= 128) begin
						sckReady <= 1'b1;
						bit_cnt <= 1'b0;
					end
				end
			
			  if (spiPOSEDGE) begin
					pos_operator <= 1'b1;
			  end
			  else begin
					if (pos_operator[0] == 1'b1) begin
						if (sckReady) begin
							bit_cnt <= bit_cnt + 1;
						end
						pos_operator <= pos_operator << 1;
					end
					else if (pos_operator[1] == 1'b1) begin
						shift_reg = shift_reg << 1;
						pos_operator <= pos_operator << 1;
					end
					else if (pos_operator[2] == 1'b1) begin
						shift_reg[0] <= sub_in;
						pos_operator <= pos_operator << 1;
					end
					else if (pos_operator[3] == 1'b1 || pos_operator[4] == 1'b1) begin
						pos_operator <= pos_operator << 1;
						if ((bit_cnt == 0) && packet) begin
							  wr_req <= 1'b1;
					   end
					end
					else begin
						wr_req <= 1'b0;
					end
			  end
			  
			  if (spiNEGEDGE) begin
					packet <= 1'b1;
					neg_operator <= 1'b1;
			  end
			  else begin
					if (neg_operator[0] == 1'b1) begin
						neg_operator <= neg_operator << 1;
						if ((bit_cnt == 0) && packet) begin
							rd_req <= 1'b1;
							shift_reg <= internal_to_SPI_in;// may need to make this happen 1 cycle after rd_req goes high
						end
					end
					else begin
						rd_req <= 1'b0;
					end
			  end
			  
		  end
		  else begin
				rd_req <= 1'b0;
				wr_req <= 1'b0;
				shift_reg <= 1'b0;
				pos_operator <= 1'b0;
				neg_operator <= 1'b0;
				packet <= 1'b0;
				bit_cnt <= 1'b0;
				sckIgnore <= 1'b0;
				sckReady <= 1'b0;
		  end
    end
end
 

endmodule
