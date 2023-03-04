//light up the leds according to a counter to cycle through every one

module top(output LED_R, output LED_G, output LED_B, output LED2, output LED3);
   reg [31:0] counter;
   wire sclk;
   assign LED_R = ~counter[26];
   assign LED_G = ~counter[27];
   assign LED_B = ~counter[28];
   assign LED2 = ~counter[29];
   assign LED3 = ~counter[30];


   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(sclk)
   );

   initial begin
      counter = 0;
   end

   always @ (posedge sclk)
   begin
      counter <= counter + 1;
   end
   
endmodule // top
