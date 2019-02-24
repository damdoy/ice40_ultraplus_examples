// opcode/status | byte | byte
//read all the data, but can write only the two bytes as opcode contains metadata
//opcodes:
//0x00 nop
//0x01 init
//0x02 write 16bits inverted
//0x03 read 16bits inverted
//0x04 write leds (16bits LSB)
//0x05 read leds (16bits LSB)

module spi_slave(input wire clk, input wire reset,
      input wire SPI_SCK, input wire SPI_SS, input wire SPI_MOSI, output wire SPI_MISO,
      output reg wr_buffer_free, input wr_en, input [15:0] wr_data,
      output reg rd_data_available, input wire rd_ack, output reg [23:0] rd_data, output reg [2:0] dbg
   );

   reg [4:0] counter_read; //max 32

   reg [1:0] spi_clk_reg;
   reg [1:0] spi_ss_reg;
   wire spi_ss_falling_edge;
   wire spi_ss_rising_edge;

   reg [1:0] mosi_reg;
   reg miso_out_reg;
   reg [7:0] state_rd;
   reg [7:0] state_wr;
   reg [15:0] wr_data_reg; //written data to send to spi/miso

   //states
   parameter IDLE = 0, INIT=IDLE+1, RD_WAIT_DATA=INIT+1, RD_WAIT_ACK=RD_WAIT_DATA+1, WR_WAIT_DATA=RD_WAIT_ACK+1, WR_WAIT_ACK=WR_WAIT_DATA+1;

   assign SPI_MISO = miso_out_reg;
   wire spi_clk_rising_edge;
   wire spi_clk_falling_edge;
   assign spi_clk_rising_edge = (spi_clk_reg[1:0] == 2'b01);
   assign spi_clk_falling_edge = (spi_clk_reg[1:0] == 2'b10);
   assign spi_ss_rising_edge = (spi_ss_reg[1:0] == 2'b01);
   assign spi_ss_falling_edge = (spi_ss_reg[1:0] == 2'b10);

   initial begin
      counter_read = 0;
      spi_clk_reg = 0;
      spi_ss_reg = 0;
      mosi_reg = 0;
      miso_out_reg = 0;
      state_rd = INIT;
      state_wr = INIT;
      wr_data_reg = 16'hcafe;

      rd_data_available = 0;
      wr_buffer_free = 1;
   end

   always @(posedge clk)
   begin
      if(reset == 1) begin
         rd_data <= 0;
         rd_data_available <= 0;
         state_rd <= INIT;
      end else begin

         spi_clk_reg <= {spi_clk_reg[0], SPI_SCK};
         mosi_reg <= {mosi_reg[0], SPI_MOSI};
         spi_ss_reg <= {spi_ss_reg[0], SPI_SS};


         if (spi_ss_falling_edge == 1 || spi_ss_rising_edge == 1) begin
            counter_read <= 0;
         end

         if(spi_clk_rising_edge == 1'b1) begin //default on spi clk
            miso_out_reg <= 0; //default
         end

         case (state_rd)
         INIT : begin // wait the init opcode from host (0x1) and nothing else
            if(spi_clk_rising_edge == 1'b1) begin
               rd_data[23:0] <= {mosi_reg[0], rd_data[23:1]};
               counter_read <= counter_read + 1;

               if(counter_read >= 23) begin //finish recv
                  if(rd_data[8:1] == 8'h1) begin //received init opcode, otherwise ignore
                     state_rd <= RD_WAIT_DATA;
                  end
                  counter_read <= 0;
               end

            end
         end
         RD_WAIT_DATA : begin
            if(spi_clk_rising_edge == 1'b1) begin

               if(counter_read == 5) begin //status, write master to slave successful
                  miso_out_reg <= 1;
               end

               if (wr_buffer_free == 0) begin //something ready to be written

                  //bits 0-7 reserved for status, starting to write wr_data_reg
                  //one clock before to be sent the next on miso
                  if(counter_read == 6) begin //status, read master to slave successful
                     miso_out_reg <= 1;
                  end else if(counter_read >= 7 && counter_read < 23) begin
                     miso_out_reg <= wr_data_reg[0];
                     wr_data_reg[15:0] <= {wr_data_reg[0], wr_data_reg[15:1]};
                  end
               end

               rd_data[23:0] <= {mosi_reg[0], rd_data[23:1]};
               counter_read <= counter_read + 1;

               if(counter_read >= 23) begin //finish recv

                  if (wr_buffer_free == 0) begin //something was written, now free
                     wr_buffer_free <= 1;
                     wr_data_reg <= 16'h00; //clear write buffer
                  end
                  rd_data_available <= 1;
                  state_rd <= RD_WAIT_ACK;
                  counter_read <= 0;
               end
            end
         end
         // waiting ack from top ready to read
         RD_WAIT_ACK : begin
            if(rd_ack == 1) begin
               rd_data_available <= 0;
               state_rd <= RD_WAIT_DATA;
            end
         end
         default : begin
         end
         endcase

         //states for writing not really needed, in case of improvement
         case (state_wr)
         INIT : begin
            state_wr <= WR_WAIT_DATA;
         end
         WR_WAIT_DATA : begin
            if (wr_en == 1 && wr_buffer_free == 1) begin
               wr_data_reg <= wr_data;
               wr_buffer_free <= 0;
            end
         end
         default : begin
         end
         endcase;
      end
   end
endmodule
