/*32 KB of memory
 15bits of 8bit address
 13bits of 32bit address
 !!address must be valid until data is read!!!
 only 32bits words addressable => otherwise adress is trunkated to lower 32bit
*/

module memory(input wire clk, input wire reset,
      input wire rd_req, input wire [14:0] rd_addr, output reg [31:0] rd_data, output reg data_valid,
      input wire wr_req, input wire [14:0] wr_addr, input wire [31:0] wr_data
   );

   //access to spram
   reg [12:0] ram_addr_0;
   reg [15:0] ram_data_in_0;
   wire [15:0] ram_data_out_0;
   reg [3:0] mask_wren_0;
   reg ram_wren_0;

   reg [12:0] ram_addr_1;
   reg [15:0] ram_data_in_1;
   wire [15:0] ram_data_out_1;
   reg [3:0] mask_wren_1;
   reg ram_wren_1;

   reg buf_rd_req;

   SB_SPRAM256KA spram0
   (
     .ADDRESS(ram_addr_0),
     .DATAIN(ram_data_in_0),
     .MASKWREN(mask_wren_0),
     .WREN(ram_wren_0),
     .CHIPSELECT(1'b1),
     .CLOCK(clk),
     .STANDBY(1'b0),
     .SLEEP(1'b0),
     .POWEROFF(1'b1),
     .DATAOUT(ram_data_out_0)
   );

   SB_SPRAM256KA spram1
   (
     .ADDRESS(ram_addr_1),
     .DATAIN(ram_data_in_1),
     .MASKWREN(mask_wren_1),
     .WREN(ram_wren_1),
     .CHIPSELECT(1'b1),
     .CLOCK(clk),
     .STANDBY(1'b0),
     .SLEEP(1'b0),
     .POWEROFF(1'b1),
     .DATAOUT(ram_data_out_1)
   );

   initial begin
   end

   always @(*)
   begin
      ram_addr_0 = {rd_addr[14:2], 2'b00}; //8K adressable words of 32bits
      ram_addr_1 = {rd_addr[14:2], 2'b00};
      if (wr_req == 1) begin
         ram_wren_0 = 1;
         ram_wren_1 = 1;
         mask_wren_0 = 4'b1111;
         mask_wren_1 = 4'b1111;
         ram_data_in_0 = wr_data[15:0];
         ram_data_in_1 = wr_data[31:16];
         ram_addr_0 = {wr_addr[14:2], 2'b00};
         ram_addr_1 = {wr_addr[14:2], 2'b00};
      end else if (wr_wreq == 0) begin
         ram_wren_0 = 0;
         ram_wren_1 = 0;
         mask_wren_0 = 4'b0000;
         mask_wren_1 = 4'b0000;
         ram_data_in_0 = 0;
         ram_data_in_1 = 0;
      end
   end

   always @(posedge clk)
   begin
      if(reset == 1) begin
         //nothing to do
      end else begin
         buf_rd_req <= rd_req;

         data_valid <= 0; //default

         if(buf_rd_req == 1) begin
            rd_data <= {ram_data_out_1, ram_data_out_0};
            data_valid <= 1;
         end
      end
   end
endmodule
