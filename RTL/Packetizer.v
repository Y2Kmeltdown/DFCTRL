module packetizer #(
    parameter 
    REG_HEADER = 2'b00,// placeholder I don't think it should be used

    WIDTH_ADDR_ACT = 11, 
    WIDTH_ACT_MEM = 8, 
    ACT_MEM_HEADER = 2'b10,
    
    WIDTH_ADDR_PARAM = 13, 
    WIDTH_PARAM_MEM = 128,
    PARAM_MEM_HEADER = 2'b01,

    WIDTH_ADDR_INST = 6,
    WIDTH_INST_MEM = 80, 
    INST_MEM_HEADER = 2'b11,

     
    WIDTH_SPI_WORD = 8,
    SPI_OUT_ADDRESS_SIZE = 4,
    SPI_IN_ADDRESS_SIZE = 4,
    SPI_OUT_ADDRESS_DEPTH = 16
    
)
(
    input                                   reset_n,
    input                                   clk,
    input                                   spi_clk,
    input                                   chip_select_n,

    input       [WIDTH_SPI_WORD-1:0]        spi_word,
    input                                   read_fifo_empty,
    input                                   write_fifo_empty,
    input                                   write_fifo_full,
    output  reg                             wr_req,
    output  reg                             rd_req,
    output  reg                             sel_ext,

    output  reg [WIDTH_ADDR_ACT-1:0]        act_mem_addr,
    output  reg [WIDTH_ACT_MEM-1:0]         act_mem_data,
    output                                  act_mem_wren,
    output  reg                             data_ready,

    output  reg [WIDTH_ADDR_PARAM-1:0]      param_mem_addr,
    output  reg [WIDTH_PARAM_MEM-1:0]       param_mem_data,
    output                                  param_mem_wren,

    output  reg [WIDTH_ADDR_INST-1:0]       inst_mem_addr,
    output  reg [WIDTH_INST_MEM-1:0]        inst_mem_data,
    output                                  inst_mem_wren,

    output  reg                             proc_reset = 1'b0,
    output  reg                             proc_enable

);

synchronizer #(
    .Width(1),
	 .Stages(2)
) sck_packet_sync ( 
    .clk  (clk),
    .reset  (!reset_n),
	 // Inputs:
    .in  (packet_done),
    // Outputs:
    .out  (packet_done_sync)
);

synchronizer #(
    .Width(11),
	 .Stages(2)
) sck_packet_cnt_sync ( 
    .clk  (clk),
    .reset  (!reset_n),
	 // Inputs:
    .in  (packet_counter),
    // Outputs:
    .out  (packet_cnt_sync)
);

synchronizer #(
    .Width(1),
	 .Stages(2)
) cs_sync ( 
    .clk  (clk),
    .reset  (!reset_n),
	 // Inputs:
    .in  (chip_select_n),
    // Outputs:
    .out  (chip_select_n_sync)
);

reg         enable;

reg [11:0]  packet_counter;
reg [4:0]   spi_clk_counter;
reg         packet_done;
reg [11:0]   write_time;
reg         SPI_done;

reg [7:0]   header;

reg [3:0]   burst_header_length;
reg [3:0]   burst_header_counter;

reg [11:0]  burst_length;
reg [11:0]  burst_counter;

reg 			rd_req_buffer;
reg 			wr_req_buffer;

reg [3:0]	reg_buffer;


reg addr_inc;


localparam integer act_mem_addr_buffer_size = (WIDTH_ADDR_ACT+WIDTH_SPI_WORD-1)/WIDTH_SPI_WORD;
localparam integer act_mem_data_buffer_size = (WIDTH_ACT_MEM+WIDTH_SPI_WORD-1)/WIDTH_SPI_WORD;

wire isHEADER_act = (header[WIDTH_SPI_WORD-1:WIDTH_SPI_WORD-2] == ACT_MEM_HEADER);
reg     [act_mem_addr_buffer_size:0] act_mem_addr_buffer;
reg     [act_mem_data_buffer_size:0] act_mem_data_buffer;


localparam integer param_mem_addr_buffer_size = (WIDTH_ADDR_PARAM+WIDTH_SPI_WORD-1)/WIDTH_SPI_WORD;
localparam integer param_mem_data_buffer_size = (WIDTH_PARAM_MEM+WIDTH_SPI_WORD-1)/WIDTH_SPI_WORD;

wire isHEADER_param = (header[WIDTH_SPI_WORD-1:WIDTH_SPI_WORD-2] == PARAM_MEM_HEADER);
reg     [param_mem_addr_buffer_size:0] param_mem_addr_buffer;
reg     [param_mem_data_buffer_size:0] param_mem_data_buffer;


localparam integer inst_mem_addr_buffer_size = (WIDTH_ADDR_INST+WIDTH_SPI_WORD-1)/WIDTH_SPI_WORD;
localparam integer inst_mem_data_buffer_size = (WIDTH_INST_MEM+WIDTH_SPI_WORD-1)/WIDTH_SPI_WORD;

wire isHEADER_inst = (header[WIDTH_SPI_WORD-1:WIDTH_SPI_WORD-2] == INST_MEM_HEADER);
reg     [inst_mem_addr_buffer_size:0] inst_mem_addr_buffer;
reg     [inst_mem_data_buffer_size:0] inst_mem_data_buffer;

wire isHEADER_reg = (header[WIDTH_SPI_WORD-1:WIDTH_SPI_WORD-2] == REG_HEADER);

localparam READ_HEADER = 1'b0;
wire isREADOP = (header[WIDTH_SPI_WORD-3] == READ_HEADER);

localparam WRITE_HEADER = 1'b1;
wire isWRITEOP = (header[WIDTH_SPI_WORD-3] == WRITE_HEADER);

localparam BURST_HEADER = 1'b1;
wire isBURSTOP = (header[WIDTH_SPI_WORD-4] == BURST_HEADER);

localparam VALID_HEADER = 2'b11;
wire isVALIDHEADER = (header[WIDTH_SPI_WORD-5:WIDTH_SPI_WORD-6] == VALID_HEADER);



// Combinatorial design for setting enable for each memory
assign {act_mem_wren, param_mem_wren, inst_mem_wren} = isHEADER_act      ? {enable, 1'b0, 1'b0} :
                                                         (isHEADER_param ? {1'b0, enable, 1'b0} :
                                                         (isHEADER_inst  ? {1'b0, 1'b0, enable} :
                                                                           {1'b0, 1'b0, 1'b0})) ;

// Packet counter
always @(negedge spi_clk or negedge reset_n or posedge SPI_done) begin
    if ((!reset_n) || SPI_done) begin
        packet_counter <= 1'b0;
        spi_clk_counter <= 1'b0;
    end
    else begin
        spi_clk_counter <= spi_clk_counter + 1'b1;
        if (spi_clk_counter == WIDTH_SPI_WORD-1) begin
            packet_done <= 1'b1;
            spi_clk_counter <= 1'b0;
            packet_counter <= packet_counter + 1'b1;
        end
        else
            packet_done <= 1'b0;
    end
end



// State Machine
reg [3:0]   r_SM_MAIN;

localparam s_HEADER = 4'b0000;
localparam s_BURST = 4'b0001;
localparam s_ADDR = 4'b0010;
localparam s_READ = 4'b0011;
localparam s_WRITE = 4'b0100;
localparam s_BURST_READ = 4'b0101;
localparam s_BURST_WRITE = 4'b0110;
localparam s_READY = 4'b0111;
localparam s_IDLE = 4'b1000;
localparam s_REG = 4'b1001;


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        r_SM_MAIN <= s_HEADER;
        header <= 1'b0;
        enable <= 1'b0;
        rd_req<= 1'b0;
        wr_req<= 1'b0;
        SPI_done <= 1'b0;
        sel_ext <= 1'b0;

        burst_header_counter <= 1'b0;
        burst_counter <= 1'b0;

        burst_header_length <= 1'b0;
        burst_length <= 1'b0;
        write_time <= 1'b0;

        addr_inc <= 1'b0;

        act_mem_addr <= 1'b0;
        act_mem_data <= 1'b0;
        act_mem_addr_buffer <= 1'b1;
        act_mem_data_buffer <= 1'b1;

        param_mem_addr <= 1'b0;
        param_mem_data <= 1'b0;
        param_mem_addr_buffer <= 1'b1;
        param_mem_data_buffer <= 1'b1;

        inst_mem_addr <= 1'b0;
        inst_mem_data <= 1'b0;
        inst_mem_addr_buffer <= 1'b1;
        inst_mem_data_buffer <= 1'b1;

        proc_reset <= 1'b0;

        data_ready <= 1'b0;
		  
		  reg_buffer <= 1'b0;
    end
    else begin
        case (r_SM_MAIN)
            s_HEADER:
                begin
                    if (!chip_select_n_sync) begin
                        if (!read_fifo_empty) begin
									rd_req_buffer <= !rd_req_buffer;
									if (!rd_req_buffer) begin
										rd_req <= !rd_req;
										header <= spi_word;
									end
                        end
                        else if (packet_cnt_sync >= 1) begin
                            rd_req <= 0;
									 rd_req_buffer <= 0;
									 if (isVALIDHEADER) begin
                              if (isHEADER_reg) begin
                                  r_SM_MAIN <= s_REG;
                              end
                              else if (isBURSTOP) begin
                                  burst_header_length <= header[WIDTH_SPI_WORD-7:0];
                                  r_SM_MAIN <= s_BURST;
                              end
                              else begin
                                  r_SM_MAIN <= s_ADDR;
                              end
                           end
                        end
                    end
						  else begin
								header <= 1'b0;
								rd_req <= 0;
						  end
                    sel_ext <= 1'b0;
                    SPI_done <= 1'b0;
                    enable <= 1'b0;
                    data_ready <= 1'b0;
                    burst_header_counter <= 1'b0;
                    burst_counter <= 1'b0;
                    burst_length <= 1'b0;
						  write_time <= 1'b0;
                    proc_reset <= 1'b0;
						  reg_buffer <= 1'b0;
                end
            s_REG:
                begin
                    proc_enable <= header[WIDTH_SPI_WORD-7];
                    proc_reset <= header[0];
						  reg_buffer <= reg_buffer + 1'b1;
						  if (reg_buffer >= 4'd15) begin
								header <= 1'b0;
								SPI_done <= 1'b1;
								r_SM_MAIN <= s_HEADER;
						  end
                end
            s_BURST:
                begin
                    if (!read_fifo_empty) begin
                        rd_req_buffer <= !rd_req_buffer;
								if (!rd_req_buffer) begin
									rd_req <= !rd_req;
									if (!rd_req) begin
										 // LOGIC HERE for reading burst length
										 burst_length <= burst_length << 8;
										 burst_length[7:0] <= spi_word;
										 burst_header_counter <= burst_header_counter + 1;
									end
								end
                    end
                    else begin
                        rd_req <= 0;
								rd_req_buffer <= 0;
								if (burst_header_counter == burst_header_length) begin
                            r_SM_MAIN <= s_ADDR;
                        end
                    end
                end
            s_ADDR:
                begin
                    if (!read_fifo_empty) begin
								rd_req_buffer <= !rd_req_buffer;
								if (!rd_req_buffer) begin
									rd_req <= !rd_req;
									if (!rd_req) begin
										 if (isHEADER_act) begin
											  act_mem_addr <= act_mem_addr << 8;
											  act_mem_addr[7:0] <= spi_word;
											  act_mem_addr_buffer <= act_mem_addr_buffer << 1;
										 end
										 else if (isHEADER_inst) begin
											  inst_mem_addr <= inst_mem_addr << 8;
											  inst_mem_addr[WIDTH_ADDR_INST-1:0] <= spi_word;
											  inst_mem_addr_buffer <= inst_mem_addr_buffer << 1;
										 end
										 else if (isHEADER_param) begin
											  param_mem_addr <= param_mem_addr << 8;
											  param_mem_addr[7:0] <= spi_word;
											  param_mem_addr_buffer <= param_mem_addr_buffer << 1;
										 end
									end
								end
                    end
                    else begin
                        rd_req <= 0;
								rd_req_buffer <= 0;
								if (act_mem_addr_buffer[act_mem_addr_buffer_size] || param_mem_addr_buffer[param_mem_addr_buffer_size] || inst_mem_addr_buffer[inst_mem_addr_buffer_size]) begin
                            if (isREADOP) begin
										  sel_ext <= 1'b1;
                                r_SM_MAIN <= s_READ;
                            end
                            else if (isWRITEOP) begin
										  sel_ext <= 1'b1;
                                r_SM_MAIN <= s_WRITE;
                            end
                        end
                    end
                end
            s_READ:
                begin
						  sel_ext <= 1'b1;
                    if (addr_inc) begin
                        addr_inc <= 1'b0;
                        param_mem_addr = param_mem_addr + 1;
                        inst_mem_addr = inst_mem_addr + 1;
                        act_mem_addr = act_mem_addr + 1;
                    end
                    if (!read_fifo_empty) begin
								rd_req_buffer <= !rd_req_buffer;
								if (!rd_req_buffer) begin
									rd_req <= !rd_req;
									if (!rd_req) begin
										 if (isHEADER_act) begin
											  act_mem_data <= act_mem_data << 8;
											  act_mem_data[7:0] <= spi_word;
											  act_mem_data_buffer <= act_mem_data_buffer << 1;
										 end
										 else if (isHEADER_inst) begin
											  inst_mem_data <= inst_mem_data << 8;
											  inst_mem_data[7:0] <= spi_word;
											  inst_mem_data_buffer <= inst_mem_data_buffer << 1;
										 end
										 else if (isHEADER_param) begin
											  param_mem_data <= param_mem_data << 8;
											  param_mem_data[7:0] <= spi_word;
											  param_mem_data_buffer <= param_mem_data_buffer << 1;
										 end
									end
								end
                    end
                    else begin
                        rd_req <= 0;
								rd_req_buffer <= 0;
								if (act_mem_data_buffer[act_mem_data_buffer_size] || param_mem_data_buffer[param_mem_data_buffer_size] || inst_mem_data_buffer[inst_mem_data_buffer_size]) begin
                            if (isBURSTOP)
                                r_SM_MAIN <= s_BURST_READ;
                            else
                                r_SM_MAIN <= s_READY;
                        end
                    end

                    enable <= 1'b0;

                end
            s_WRITE:
                begin  
                    sel_ext <= 1'b1;
                    wr_req <= 1'b1;
                    if (wr_req) begin
								wr_req <= 1'b0;
								if (isBURSTOP) begin
									r_SM_MAIN <= s_BURST_WRITE;
								end
								else begin
									write_time <= packet_cnt_sync;
									r_SM_MAIN <= s_READY;
								end
                    end
                end

            s_BURST_READ:
                begin
                    act_mem_data_buffer <= 1'b1;
                    param_mem_data_buffer <= 1'b1;
                    inst_mem_data_buffer <= 1'b1;
                    sel_ext <= 1'b1;
                    enable <= 1'b1;
                    if (burst_counter < burst_length) begin
                        burst_counter = burst_counter + 1;
                        addr_inc <= 1'b1;
                        r_SM_MAIN <= s_READ;
                    end
                    else begin
                        act_mem_addr_buffer <= 1'b1;
                        param_mem_addr_buffer <= 1'b1;
                        inst_mem_addr_buffer <= 1'b1;
                        r_SM_MAIN <= s_READY;
                    end
                end
            s_BURST_WRITE:
                begin
                    sel_ext <= 1'b1; 
                    act_mem_data_buffer <= 1'b1;
                    param_mem_data_buffer <= 1'b1;
                    inst_mem_data_buffer <= 1'b1;
                    act_mem_addr_buffer <= 1'b1;
                    param_mem_addr_buffer <= 1'b1;
                    inst_mem_addr_buffer <= 1'b1;
                    if (!write_fifo_full) begin
                        if (burst_counter < burst_length) begin
                            param_mem_addr = param_mem_addr + 1;
                            inst_mem_addr = inst_mem_addr + 1;
                            act_mem_addr = act_mem_addr + 1;
                            burst_counter = burst_counter + 1;
                            r_SM_MAIN <= s_WRITE; 
                        end
                        else begin 
									write_time <= packet_cnt_sync;
                           r_SM_MAIN <= s_READY;
                        end
                    end
                end
            s_READY:
                begin
						wr_req <= 1'b0;
						act_mem_addr_buffer <= 1'b1;
						act_mem_data_buffer <= 1'b1;
						param_mem_addr_buffer <= 1'b1;
						param_mem_data_buffer <= 1'b1;
						inst_mem_addr_buffer <= 1'b1;
						inst_mem_data_buffer <= 1'b1;

						if (isREADOP) begin
							 sel_ext <= 1'b1;
							 enable <= 1'b1;
							 SPI_done <= 1'b1;
							 header <= 1'b0;
							 r_SM_MAIN <= s_HEADER;
						end
						else if (isWRITEOP) begin
							 data_ready <= 1'b1;
							 if (!read_fifo_empty) begin   
								  rd_req <= !rd_req;
							 end
							 else begin
								  rd_req <= 1'b0;
							 end
							 
							 if (write_fifo_empty) begin
								  SPI_done <= 1'b1;
								  header <= 1'b0;
								  r_SM_MAIN <= s_HEADER;
							 end
							 
						end
                    
                end
            default:
                r_SM_MAIN <= s_HEADER;
        endcase
    end
end

endmodule