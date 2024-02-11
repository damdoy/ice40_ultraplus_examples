`include "bcd_to_7seg.v"

// A verilog module transforms a 4-bit number into a displayable 7-bit value.
// This number is incremented every ~0.25sec.
module top(output LED_R, output LED_G, output LED_B,
   output P12, output P13, output P18, output P44, output P45 , output P46, output P47);

   reg [31:0] counter_time;
   reg [3:0] counter_number;

   wire [6:0] seg_out;
   wire clk;
   wire sclk;
   bcd_to_7seg bcd_to_7seg_inst(.bcd_in(counter_number), .seg_out(seg_out));

   //green led to tell when ready
   assign LED_R = 1;
   assign LED_G = 0;
   assign LED_B = 1;

   //see bcd_to_7seg.v for segments placement
   //using a common anode 7segments, so invert values
   assign P45 = seg_out[0]; //a
   assign P44 = seg_out[1]; //b
   assign P18 = seg_out[2]; //c
   assign P13 = seg_out[3]; //d
   assign P12 = seg_out[4]; //e
   assign P46 = seg_out[5]; //f
   assign P47 = seg_out[6]; //g

   initial begin
      counter_time = 0;
      counter_number = 0;
   end
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk)
   );
   SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .PLLOUT_SELECT("GENCLK"),
      .DIVR(4'b0000),
      .DIVF(7'b0000011),
      .DIVQ(3'b101),
      .FILTER_RANGE(3'b100),
    ) SB_PLL40_CORE_inst (
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .PLLOUTCORE(sclk),
      .REFERENCECLK(clk)
   );
   always @ (posedge sclk)
   begin
      counter_time <= counter_time + 1;

      if(counter_time == 32'h400000) begin // around 0.25 sec
         counter_time <= 0;
         counter_number <= counter_number + 1;
      end

   end

endmodule
