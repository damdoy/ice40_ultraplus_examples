/*registers:
   0x0 LEDS (first 3 bits)
*/

module gpio_mm(input wire clk, input wire reset,
      output wire LED_R, output wire LED_G, output wire LED_B,
      input wire rd_req, input wire [31:0] rd_addr, output reg [31:0] rd_data, output reg data_valid,
      input wire wr_req, input wire [31:0] wr_addr, input wire [31:0] wr_data
   );

   reg[31:0] gpio_reg;

   assign LED_R = ~gpio_reg[0];
   assign LED_G = ~gpio_reg[1];
   assign LED_B = ~gpio_reg[2];

   initial begin
      gpio_reg = 0;
   end

   always @(posedge clk)
   begin
      if(reset == 1) begin
         gpio_reg <= 0;
      end else begin
         //defaults
         data_valid <= 0;

         if(rd_req == 1 && rd_addr == 0) begin
            rd_data <= gpio_reg;
            data_valid <= 1;
         end

         if(wr_req == 1 && wr_addr == 0) begin
            gpio_reg <= wr_data;
         end
      end
   end
endmodule
