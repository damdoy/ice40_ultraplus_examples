`include "bcd_to_7seg.v"

// A verilog module transforms a 4-bit number into a displayable 7-bit value.
// This number is incremented every ~0.25sec.
module top(output LED_R, output LED_G, output LED_B,
   output P6, output P9, output P10, output P11, output P12, output P13, output P18);

   reg [31:0] counter_time;
   reg [3:0] counter_number;

   wire [6:0] seg_out;
   wire sclk;
   bcd_to_7seg bcd_to_7seg_inst(.bcd_in(counter_number), .seg_out(seg_out));

   //green led to tell when ready
   assign LED_R = 1;
   assign LED_G = 0;
   assign LED_B = 1;

   //see bcd_to_7seg.v for segments placement
   //using a common anode 7segments, so invert values
   assign P6 = ~seg_out[0]; //a
   assign P9 = ~seg_out[1]; //b
   assign P10 = ~seg_out[2]; //c
   assign P11 = ~seg_out[3]; //d
   assign P12 = ~seg_out[4]; //e
   assign P13 = ~seg_out[5]; //f
   assign P18 = ~seg_out[6]; //g

   initial begin
      counter_time = 0;
      counter_number = 0;
   end
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(sclk)
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
