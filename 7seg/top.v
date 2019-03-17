`include "bcd_to_7seg.v"

// A verilog module transforms a 4-bit number into a displayable 7-bit value.
// This number is incremented every ~0.25sec.
module top(input [3:0] SW, input clk, output LED_R, output LED_G, output LED_B, input [3:0] SW,
   output IOT_39A, output IOT_38B, output IOT_42B, output IOT_43A, output IOT_45A_G1, output IOT_51A, output IOT_50B);

   reg [31:0] counter_time;
   reg [3:0] counter_number;

   wire [6:0] seg_out;

   bcd_to_7seg bcd_to_7seg_inst(.bcd_in(counter_number), .seg_out(seg_out));

   //green led to tell when ready
   assign LED_R = 1;
   assign LED_G = 0;
   assign LED_B = 1;

   //see bcd_to_7seg.v for segments placement
   //using a common anode 7segments, so invert values
   assign IOT_38B = ~seg_out[0]; //a
   assign IOT_39A = ~seg_out[1]; //b
   assign IOT_50B = ~seg_out[2]; //c
   assign IOT_51A = ~seg_out[3]; //d
   assign IOT_45A_G1 = ~seg_out[4]; //e
   assign IOT_42B = ~seg_out[5]; //f
   assign IOT_43A = ~seg_out[6]; //g

   initial begin
      counter_time = 0;
      counter_number = 0;
   end

   always @(posedge clk)
   begin
      counter_time <= counter_time + 1;

      if(counter_time == 32'h400000) begin // around 0.25 sec
         counter_time <= 0;
         counter_number <= counter_number + 1;
      end

   end

endmodule
