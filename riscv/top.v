// `include "../spi/spi_slave.v"
`include "gpio_mm.v"
`include "memory.v"
`include "spi_mm.v"
`include "simple_riscv_cpu/simple_cpu/simple_cpu.v"

module top(input [3:0] SW, input clk, output LED_R, output LED_G, output LED_B, input SPI_SCK, input SPI_SS, input SPI_MOSI, output SPI_MISO, input [3:0] SW);

   reg cpu_reset;
   wire cpu_read_req;
   wire [31:0] cpu_read_addr;
   reg [31:0] cpu_read_data;
   reg cpu_read_data_valid;
   wire cpu_write_req;
   wire [31:0] cpu_write_addr;
   wire [31:0] cpu_write_data;
   wire [3:0] cpu_memory_mask;
   wire cpu_error_instruction;
   wire [31:0] cpu_debug;

   //signals for the spi mm
   reg spi_reset;
   reg spi_rd_req;
   reg [31:0] spi_rd_addr;
   wire [31:0] spi_rd_data;
   wire spi_rd_valid;
   reg spi_wr_req;
   reg [31:0] spi_wr_addr;
   reg [31:0] spi_wr_data;
   wire spi_firm_wr;
   wire [15:0] spi_firm_data;
   reg spi_firm_ack;
   wire spi_cpu_start;
   reg spi_cpu_start_ack;

   //signals for the gpio_mm
   reg gpio_reset;
   reg gpio_rd_req;
   reg [31:0] gpio_rd_addr;
   wire [31:0] gpio_rd_data;
   wire gpio_rd_valid;
   reg gpio_wr_req;
   reg [31:0] gpio_wr_addr;
   reg [31:0] gpio_wr_data;

   reg memory_reset;
   reg memory_rd_req;
   reg [31:0] memory_rd_addr;
   wire [31:0] memory_rd_data;
   wire memory_rd_valid;
   reg memory_wr_req;
   reg [31:0] memory_wr_addr;
   reg [31:0] memory_wr_data;

   spi_mm spi_mm_inst(.clk(clk), .reset(spi_reset),
      .SPI_SCK(SPI_SCK), .SPI_SS(SPI_SS), .SPI_MOSI(SPI_MOSI), .SPI_MISO(SPI_MISO),
      .rd_req(spi_rd_req), .rd_addr(spi_rd_addr), .rd_data(spi_rd_data), .data_valid(spi_rd_valid),
      .wr_req(spi_wr_req), .wr_addr(spi_wr_addr), .wr_data(spi_wr_data),
      .firm_wr(spi_firm_wr), .firm_data(spi_firm_data), .firm_ack(spi_firm_ack),
      .cpu_start(spi_cpu_start), .cpu_start_ack(spi_cpu_start_ack)
   );

   simple_cpu simple_cpu_inst(.clk(clk), .reset(cpu_reset),
      .read_req(cpu_read_req), .read_addr(cpu_read_addr), .read_data(cpu_read_data), .read_data_valid(cpu_read_data_valid),
      .write_req(cpu_write_req), .write_addr(cpu_write_addr), .write_data(cpu_write_data), .memory_mask(cpu_memory_mask),
      .error_instruction(cpu_error_instruction), .debug(cpu_debug)
   );

   gpio_mm gpio_mm_inst(.clk(clk), .reset(gpio_reset),
      .LED_R(LED_R), .LED_G(LED_G), .LED_B(LED_B),
      .rd_req(gpio_rd_req), .rd_addr(gpio_rd_addr), .rd_data(gpio_rd_data), .data_valid(gpio_rd_valid),
      .wr_req(gpio_wr_req), .wr_addr(gpio_wr_addr), .wr_data(gpio_wr_data)
   );

   memory memory_inst(.clk(clk), .reset(memory_reset),
      .rd_req(memory_rd_req), .rd_addr(memory_rd_addr), .rd_data(memory_rd_data), .data_valid(memory_rd_valid),
      .wr_req(memory_wr_req), .wr_addr(memory_wr_addr), .wr_data(memory_wr_data)
   );

   //register file investigation
   reg [31:0] state;

   parameter IDLE=0, INIT=IDLE+1, REQ_READ_SPI_STATUS=INIT+1, READ_SPI_STATUS=REQ_READ_SPI_STATUS+1,
            REQ_SPI_READ_DATA=READ_SPI_STATUS+1, SPI_READ_DATA=REQ_SPI_READ_DATA+1,
            WRITE_MEMORY=SPI_READ_DATA+1, READ_REQ_MEMORY=WRITE_MEMORY+1, READ_MEMORY=READ_REQ_MEMORY+1,
            START_CPU=READ_MEMORY+1;

   reg [31:0] spi_recv_data_reg;
   reg handle_data;

   reg [15:0] counter_firmware_address; //address to write firmware to
   reg [15:0] firmware_data_buf; //since we receive 16bits data and want to write 32, keep buffer

   reg [23:0] reg_bits_inversion;

   reg cpu_read_req_buf; //to detect rising edge

   initial begin

      cpu_reset = 1; //cpu in reset at start

      spi_reset = 0;
      spi_wr_en = 0;
      spi_wr_data = 0;
      spi_rd_ack = 0;

      // led = 0;
      spi_recv_data_reg = 0;
      spi_firm_ack = 0;
      spi_cpu_start_ack = 0;
      handle_data = 0;

      state = REQ_READ_SPI_STATUS;

      memory_reset = 0;
      memory_rd_req = 0;
      memory_rd_addr = 0;
      memory_wr_req = 0;
      memory_wr_addr = 0;
      memory_wr_data = 0;

      gpio_reset = 0;

      counter_firmware_address = 0;
      firmware_data_buf = 0;
   end

   always @(posedge clk)
   begin

      //defaults
      spi_rd_ack <= 0;
      spi_wr_en <= 0;
      spi_firm_ack <= 0;

      gpio_wr_req <= 0;
      gpio_wr_addr <= 0;
      gpio_wr_data <= 0;

      cpu_read_data <= 0;
      cpu_read_data_valid <= 0;
      cpu_read_req_buf <= cpu_read_req;

      spi_rd_req <= 0;
      spi_rd_addr <= 0;
      spi_cpu_start_ack <= 0;

      spi_wr_req <= 0;
      spi_wr_addr <= 0;
      spi_wr_data <= 0;

      memory_rd_req <= 0;
      memory_wr_req <= 0;
      memory_wr_addr <= 0;
      memory_wr_data <= 0;

      //handling of SPI messages from host
      case (state)
      IDLE: begin
      end
      INIT: begin
      end
      REQ_READ_SPI_STATUS: begin
         if(spi_firm_wr == 1) begin //spi module received a special opcode to write firmware to ram
            spi_firm_ack <= 1;
            state <= WRITE_MEMORY;
         end else if (spi_cpu_start == 1) begin //special opcode to start CPU (deassert reset)
            spi_cpu_start_ack <= 1;
            state <= START_CPU;
         end
      end
      WRITE_MEMORY: begin //write the firmware to memory, auto increment address
         if(counter_firmware_address[0] == 0) begin
            firmware_data_buf <= spi_firm_data[15:0];
         end else begin
            memory_wr_data <= {spi_firm_data[15:0], firmware_data_buf};
            memory_wr_req <= 1;
            memory_wr_addr <= {counter_firmware_address[13:1], 2'b00};

            if({spi_firm_data[15:0], firmware_data_buf} == 32'h00e7a023 && {counter_firmware_address[13:1], 2'b00} == 16'h8) begin
               gpio_wr_req <= 1;
               gpio_wr_addr <= 0;
               gpio_wr_data <= 32'b001;
            end
         end

         counter_firmware_address <= counter_firmware_address + 1;

         state <= REQ_READ_SPI_STATUS;
      end
      START_CPU: begin
         cpu_reset <= 0;
         state <= REQ_READ_SPI_STATUS;
      end

      endcase

      // cpu makes a read request
      if(cpu_read_req_buf == 0 && cpu_read_req == 1) begin //only rising edge

         //memory
         if(cpu_read_addr[31:15] == 17'h0 ) begin //0x0000 - 0x7fff
            memory_rd_req <= 1;
            memory_rd_addr <= cpu_read_addr[14:0];
         end
         //SPI
         if(cpu_read_addr[31:8] == 24'h000080 ) begin //0x8000 - 0x80ff ==> 0x000080zz
            spi_rd_req <= 1;
            spi_rd_addr <= cpu_read_addr[7:0];
         end
         //gpio
         if(cpu_read_addr[31:8] == 24'h000081) begin //0x8100 - 0x81ff
            gpio_rd_req <= 1;
            gpio_rd_addr <= cpu_read_addr[7:0];
         end

      end

      //answers from the read of the various MM modules => give value to cpu
      if(memory_rd_valid == 1) begin
         cpu_read_data <= memory_rd_data;
         cpu_read_data_valid <= 1;
      end

      if(spi_rd_valid == 1) begin
         cpu_read_data <= spi_rd_data;
         cpu_read_data_valid <= 1;
      end

      if(gpio_rd_valid == 1) begin
         cpu_read_data <= gpio_rd_data;
         cpu_read_data_valid <= 1;
      end

      //cpu makes a write request
      if(cpu_write_req == 1) begin
         //memory
         if(cpu_write_addr[31:15] == 17'h0 ) begin //0x0000 - 0x7fff
            memory_wr_req <= 1;
            memory_wr_addr <= cpu_write_addr[14:0];
            memory_wr_data <= cpu_write_data;
         end
         //SPI
         if(cpu_write_addr[31:8] == 24'h000080 ) begin //0x8000 - 0x80ff ==> 0x000080zz
            spi_wr_req <= 1;
            spi_wr_addr <= cpu_write_addr[7:0];
            spi_wr_data <= cpu_write_data;
            // spi_wr_data <= 24'h123456;
         end
         //gpio
         if(cpu_write_addr[31:8] == 24'h000081) begin //0x8100 - 0x81ff
            gpio_wr_req <= 1;
            gpio_wr_addr <= cpu_write_addr[7:0];
            gpio_wr_data <= cpu_write_data;
         end

      end
   end

endmodule
