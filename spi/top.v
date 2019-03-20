`include "spi_slave.v"

//TODO: description

module top(input [3:0] SW, input clk, output LED_R, output LED_G, output LED_B, input SPI_SCK, input SPI_SS, input SPI_MOSI, output SPI_MISO, input [3:0] SW);

   reg spi_reset;
   wire spi_wr_buffer_free;
   reg spi_wr_en;
   reg [23:0] spi_wr_data;
   wire spi_rd_data_available;
   reg spi_rd_ack;
   wire [31:0] spi_rd_data;

   spi_slave spi_slave_inst(.clk(clk), .reset(spi_reset),
      .SPI_SCK(SPI_SCK), .SPI_SS(SPI_SS), .SPI_MOSI(SPI_MOSI), .SPI_MISO(SPI_MISO),
      .wr_buffer_free(spi_wr_buffer_free), .wr_en(spi_wr_en), .wr_data(spi_wr_data),
      .rd_data_available(spi_rd_data_available), .rd_ack(spi_rd_ack), .rd_data(spi_rd_data)
   );

   reg [2:0] led;

   reg [31:0] spi_recv_data_reg;
   reg handle_data;

   reg [23:0] reg_bits_inversion;

   assign LED_R = ~led[0];
   assign LED_G = ~led[1];
   assign LED_B = ~led[2];

   initial begin
      spi_reset = 0;
      spi_wr_en = 0;
      spi_wr_data = 0;
      spi_rd_ack = 0;

      led = 0;
      spi_recv_data_reg = 0;
      handle_data = 0;
   end

   always @(posedge clk)
   begin

      //defaults
      spi_rd_ack <= 0;
      spi_wr_en <= 0;

      if(spi_rd_data_available == 1) begin
         spi_recv_data_reg <= spi_rd_data;
         spi_rd_ack <= 1;
         handle_data <= 1;
      end

      if(handle_data == 1) begin

         if(spi_recv_data_reg[7:0] == 2) begin //set bit inversion
            reg_bits_inversion[23:0] <= ~spi_recv_data_reg[31:8];
         end

         if(spi_recv_data_reg[7:0] == 3) begin //answer bit inversion
            spi_wr_en <= 1;
            spi_wr_data[23:0] <= reg_bits_inversion[23:0];
         end

         if(spi_recv_data_reg[7:0] == 4) begin
            led[2:0] <= spi_recv_data_reg[26:24];
         end

         if(spi_recv_data_reg[7:0] == 5) begin
            spi_wr_en <= 1;
            spi_wr_data[23:0] <= {21'b0 ,led[2:0]};
         end
         handle_data <= 0;
      end
   end

endmodule
