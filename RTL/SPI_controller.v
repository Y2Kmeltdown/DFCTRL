module spi_controller #(
    parameter 
    SPI_BUS_WIDTH = 8,
    SPI_OUT_ADDRESS_SIZE = 8,
    SPI_IN_ADDRESS_SIZE = 4
    )
    (
    input           reset_n,

    // SPI Components
    input           spi_clk,
    input           mosi,
    output          miso,
    input           chip_select_n,
    input   [1:0]   set_reg,

    // Internal Components
    input           internal_clk,
    input   [7:0]   internal_in,
    output  [7:0]   internal_out,
    input           rd_req,
    input           wr_req,

    // FIFO Components
    output          SPI_write_full,
    output          SPI_write_empty,
    output          SPI_read_full,
    output          SPI_read_empty

);

wire [7:0]  spi_in;
wire [7:0]  spi_out;
wire        spi_wr_req;
wire        spi_rd_req;

// SPI clk configuration depending on mode set in set_reg
wire spi_clk_in;

wire isMode0 = (set_reg == 2'b00);
wire isMode1 = (set_reg == 2'b01);
wire isMode2 = (set_reg == 2'b10);
wire isMode3 = (set_reg == 2'b11);

assign spi_clk_in =  isMode0 ? spi_clk  :
                    (isMode1 ? !spi_clk :
                    (isMode2 ? !spi_clk :
                    (isMode3 ? spi_clk  :
                                spi_clk  )));



SPI #(
    .SPI_BUS_WIDTH(SPI_BUS_WIDTH)
)
SPI_BUS
(
    .clk(internal_clk),
    .chip_select_n(chip_select_n),
    .sub_clk(spi_clk_in),
    .sub_in(mosi),
    .sub_out(miso),
    .reset_n(reset_n),
    .wr_req(spi_wr_req),
    .rd_req(spi_rd_req),

    .internal_to_SPI_in(spi_in),
    .SPI_to_internal_out(spi_out)
);

FIFO #(
    .DSIZE(SPI_BUS_WIDTH),
    .ASIZE(SPI_OUT_ADDRESS_SIZE)
) 
internal_to_spi_FIFO (
    .wdata(internal_in),
    .winc(wr_req),
    .wfull(SPI_write_full),
    .wclk(internal_clk),
    .wrst_n(reset_n),

    .rdata(spi_in),
    .rinc(spi_rd_req),
    .rempty(SPI_write_empty),
    .rclk(internal_clk),
    .rrst_n(reset_n)
);

FIFO #(
    .DSIZE(SPI_BUS_WIDTH),
    .ASIZE(SPI_IN_ADDRESS_SIZE)
) 
spi_to_internal_FIFO (
    .wdata(spi_out),
    .winc(spi_wr_req),
    .wfull(SPI_read_full),
    .wclk(internal_clk),
    .wrst_n(reset_n),

    .rdata(internal_out),
    .rinc(rd_req),
    .rempty(SPI_read_empty),
    .rclk(internal_clk),
    .rrst_n(reset_n)
);
    
endmodule
