// opcode/status | byte | byte | byte
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
      output reg wr_buffer_free, input wr_en, input [23:0] wr_data,
      output reg rd_data_available, input wire rd_ack, output reg [31:0] rd_data
   );

   reg [4:0] counter_read; //max 32

   reg [1:0] spi_clk_reg;
   reg [1:0] spi_ss_reg;
   wire spi_ss_falling_edge;
   wire spi_ss_rising_edge;

   reg [1:0] mosi_reg;
   reg miso_out_reg;
   reg [7:0] state_rd;

   reg wr_reg_full;
   reg [23:0] wr_data_reg; //written data to send to spi/miso
   reg wr_queue_full;
   reg [23:0] wr_data_queue; //waiting to be written in the register, avoid a write while communcating with SPI

   reg buffer_rd_ack;
   reg [31:0] rd_data_local;

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
      wr_reg_full = 0;
      wr_data_reg = 24'hcafe77;
      wr_queue_full = 0;
      wr_data_queue = 0;

      buffer_rd_ack = 0;
      rd_data = 0;
      rd_data_local = 0;

      rd_data_available = 0;
      // wr_buffer_free = 1;
   end

   always @(posedge clk)
   begin
      if(reset == 1) begin
         rd_data <= 0;
         rd_data_local <= 0;
         rd_data_available <= 0;
         state_rd <= INIT;
      end else begin

         spi_clk_reg <= {spi_clk_reg[0], SPI_SCK};
         mosi_reg <= {mosi_reg[0], SPI_MOSI};
         spi_ss_reg <= {spi_ss_reg[0], SPI_SS};
         wr_buffer_free <= (~wr_queue_full) & (~wr_reg_full);

         if (spi_ss_falling_edge == 1 || spi_ss_rising_edge == 1) begin
            counter_read <= 0;
         end

         if(spi_clk_rising_edge == 1'b1) begin //default on spi clk
            miso_out_reg <= 0; //default
         end

         case (state_rd)
         INIT : begin // wait the init opcode from host (0x1) and nothing else
            if(spi_clk_rising_edge == 1'b1) begin
               rd_data_local[31:0] <= {mosi_reg[0], rd_data_local[31:1]};
               counter_read <= counter_read + 1;

               if(counter_read == 5) begin //status, write master to slave successful
                  miso_out_reg <= 1;
               end

               if(counter_read >= 31) begin //finish recv
                  if(rd_data_local[8:1] == 8'h1) begin //received init opcode, otherwise ignore
                     state_rd <= RD_WAIT_DATA;
                  end
                  counter_read <= 0;
               end

            end
         end
         RD_WAIT_DATA : begin
            if(spi_clk_rising_edge == 1'b1) begin
               if(counter_read == 5 && rd_data_available == 0) begin //status, write master to slave successful
                  miso_out_reg <= 1;
               end

               if (wr_reg_full == 1) begin //something ready to be written

                  //bits 0-7 reserved for status, starting to write wr_data_reg
                  //one clock before to be sent the next on miso
                  if(counter_read == 6) begin //status, read master to slave successful
                     miso_out_reg <= 1;
                  end else if(counter_read >= 7 && counter_read < 31) begin
                     miso_out_reg <= wr_data_reg[0];
                     wr_data_reg[23:0] <= {wr_data_reg[0], wr_data_reg[23:1]};
                  end
               end

               rd_data_local[31:0] <= {mosi_reg[0], rd_data_local[31:1]};
               counter_read <= counter_read + 1;

               if(counter_read >= 31) begin //finish recv

                  if (wr_reg_full == 1) begin //something was written, now free
                     wr_reg_full <= 0;
                     wr_data_reg <= 24'h00; //clear write buffer
                  end

                  if(rd_data_available == 0) begin
                     rd_data_available <= 1;
                     rd_data <= {mosi_reg[0], rd_data_local[31:1]};
                  end
                  state_rd <= RD_WAIT_DATA;
                  counter_read <= 0;
               end
            end
         end
         default : begin
         end
         endcase

         if(rd_ack == 1 && rd_data_available == 1 && buffer_rd_ack == 0) begin
            buffer_rd_ack <= 1;
         end

         if(buffer_rd_ack == 1 && counter_read == 0) begin
            rd_data_available <= 0;
            buffer_rd_ack <= 0;
         end

         //write
         if (wr_en == 1 && wr_buffer_free == 1) begin
            wr_queue_full <= 1;
            wr_data_queue <= wr_data;
         end

         //move from queue to reg only when no com (counter_read == 0)
         if(wr_queue_full == 1 && counter_read == 0) begin
            wr_data_reg <= wr_data_queue;
            wr_queue_full <= 0;
            wr_reg_full <= 1;
         end
      end
   end
endmodule
