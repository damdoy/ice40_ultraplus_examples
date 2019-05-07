/*registers:
   0x0 status (bit 0: read buffer full, bit 1: write buffer full) (R only)
   0x4 read data R only
   0x8 assert read W only (write something else than 0)
   0xC write data

   opcodes
   0x0     | Nop, does nothing
   0x1     | init
   0x2     | Sends 16bits of data (incremental address) ==> will be britten to ram
   0x3     | Starts the cpu
   0x4     | Writes 24bits data to the fpga
   0x5     | reads 24bits data from the fpga

   //byte2 | byte1 | byte0 | opcode/status
*/
`include "../spi/spi_slave.v"

module spi_mm(input wire clk, input wire reset,
      input wire SPI_SCK, input wire SPI_SS, input wire SPI_MOSI, output wire SPI_MISO,
      input wire rd_req, input wire [31:0] rd_addr, output reg [31:0] rd_data, output reg data_valid,
      input wire wr_req, input wire [31:0] wr_addr, input wire [31:0] wr_data,
      output reg firm_wr, output reg [15:0] firm_data, input wire firm_ack,
      output reg cpu_start, input wire cpu_start_ack
   );

   //dedicated spi signals
   wire wr_buffer_free;
   reg wr_en;
   reg [23:0] spi_module_wr_data;
   wire rd_data_available;
   reg rd_ack;
   wire [31:0] spi_module_rd_data;

   spi_slave spi_slave_inst(.clk(clk), .reset(reset),
      .SPI_SCK(SPI_SCK), .SPI_SS(SPI_SS), .SPI_MOSI(SPI_MOSI), .SPI_MISO(SPI_MISO),
      .wr_buffer_free(wr_buffer_free), .wr_en(wr_en), .wr_data(spi_module_wr_data),
      .rd_data_available(rd_data_available), .rd_ack(rd_ack), .rd_data(spi_module_rd_data)
   );

   //internal signals and registers
   reg[31:0] status_register;
   reg[31:0] read_data_register;
   reg[31:0] assert_read_register;
   reg[31:0] write_data_register;

   reg spi_started;

   initial begin
      wr_en = 0;
      spi_module_wr_data = 0;
      rd_ack = 0;

      status_register = 0;
      read_data_register = 0;
      assert_read_register = 0;
      write_data_register = 0;

      firm_wr = 0;
      firm_data = 0;
      cpu_start = 0;
   end

   always @(posedge clk)
   begin
      if(reset == 1) begin
         wr_en <= 0;
         spi_module_wr_data <= 0;
         rd_ack <= 0;
         // cpu_start <= 0;

         status_register <= {1, 31'h0};
         read_data_register <= 0;
         assert_read_register <= 0;
         write_data_register <= 0;
      end else begin

         //default
         rd_ack <= 0;
         rd_data <= 0;
         data_valid <= 0;
         wr_en <= 0;

         status_register[1] <= wr_buffer_free;

         if(rd_data_available == 1 && status_register[0] == 0) begin
            if(spi_module_rd_data[7:0] == 8'h0) begin //NOP, does nothing, is not taken into accounts
               rd_ack <= 1;
            end else if(spi_module_rd_data[7:0] == 8'h2) begin //something needs to be written in memory
               if(firm_wr == 0) begin
                  firm_wr <= 1;
                  rd_ack <= 1;
                  firm_data <= spi_module_rd_data[23:8];
               end
            end else if (spi_module_rd_data[7:0] == 8'h3) begin
               if(cpu_start == 0) begin
                  cpu_start <= 1;
                  rd_ack <= 1;
               end
            end else begin
               read_data_register <= spi_module_rd_data;
               // rd_ack <= 1;
               status_register[0] <= 1;
            end
         end

         if(cpu_start_ack == 1 && cpu_start == 1) begin
            cpu_start <= 0;
         end

         if(firm_ack == 1 && firm_wr == 1) begin
            firm_wr <= 0;
         end

         if(rd_req == 1) begin
            if(rd_addr == 32'h0) begin
               rd_data <= status_register;
               data_valid <= 1;
            end else if(rd_addr == 32'h4) begin
               rd_data <= read_data_register;
               data_valid <= 1;
            end else if(rd_addr == 32'h8) begin
               rd_data <= assert_read_register;
               data_valid <= 1;
            end else if(rd_addr == 32'hC) begin
               rd_data <= write_data_register;
               data_valid <= 1;
            end
         end

         if(wr_req == 1) begin
            if(wr_addr == 32'h8) begin //assert read
               status_register[0] <= 0;
               rd_ack <= 1; //tell spi module read ack
            end else if(wr_addr == 32'hC) begin
               write_data_register <= wr_data;
               wr_en <= 1;
               spi_module_wr_data <= wr_data;
            end
         end
      end
   end
endmodule
