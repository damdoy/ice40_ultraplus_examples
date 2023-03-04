`include "calc.v"
`include "calc_dsp.v"

module top(output LED_R, output LED_G, output LED_B);

   wire correct;
   wire sclk;
   //implementation without DSP
   // calc calc_inst(
   //    .clk(sclk), .correct(correct)
   // );

   //implementation with DSP
   calc_dsp calc_dsp_inst(
      .clk(sclk), .correct(correct)
   );

   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(sclk)
   );
  //leds are active low
  assign LED_R = ~correct;
  assign LED_G = ~correct;
  assign LED_B = ~correct;

  initial begin
  end

  always @(posedge sclk)
  begin
  end

endmodule
