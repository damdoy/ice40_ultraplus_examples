//light up the leds depending on each switch (careful, leds are active low, but so are the switches)

module switch(input P6, input P9, input P10, output LED_R, output LED_G, output LED_B);
  
  assign LED_R = P6;
  assign LED_G = P9;
  assign LED_B = P10;

endmodule
