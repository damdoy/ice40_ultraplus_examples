//light up the leds according to a counter to cycle through every one

module top(output LED_R, output LED_G, output LED_B);
   reg [25:0] counter;
   assign LED_R = ~counter[23];
   assign LED_G = ~counter[24];
   assign LED_B = ~counter[25];

   initial begin
      counter = 0;
   end

   always #10
   begin
      counter <= counter + 1;
   end
   
endmodule // top
