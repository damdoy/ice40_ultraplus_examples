`include "calc.v"
`include "calc_dsp.v"

module top(output LED_R, output LED_G, output LED_B, output LED2, output LED3);

   wire correct;
   wire clk;
   wire sclk;
   //implementation without DSP
   // calc calc_inst(
   //    .clk(sclk), .correct(correct)
   // );

   assign LED2 = 0;
   assign LED3 = 0;

   //implementation with DSP
   calc_dsp calc_dsp_inst(
      .clk(sclk), .correct(correct)
   );

   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk)
   );
   SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .PLLOUT_SELECT("GENCLK"),
      .DIVR(4'b0000),
      .DIVF(7'b0000001),
      .DIVQ(3'b101),
      .FILTER_RANGE(3'b100),
    ) SB_PLL40_CORE_inst (
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .PLLOUTCORE(sclk),
      .REFERENCECLK(clk)
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
