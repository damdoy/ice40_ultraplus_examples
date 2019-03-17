//transforms 4bits numbers to a 7seg display
//
//   --a--
//  |     |
//  f     b
//  |     |
//   --g--
//  |     |
//  e     c
//  |     |
//   --d--
//
// 7'gfedcba (a = LSB)
module bcd_to_7seg(input [3:0] bcd_in, output [6:0] seg_out);

   assign seg_out =  (bcd_in==4'h0) ? 7'b0111111 :
                     (bcd_in==4'h1) ? 7'b0000110 :
                     (bcd_in==4'h2) ? 7'b1011011 :
                     (bcd_in==4'h3) ? 7'b1001111 :
                     (bcd_in==4'h4) ? 7'b1100110 :
                     (bcd_in==4'h5) ? 7'b1101101 :
                     (bcd_in==4'h6) ? 7'b1111101 :
                     (bcd_in==4'h7) ? 7'b0000111 :
                     (bcd_in==4'h8) ? 7'b1111111 :
                     (bcd_in==4'h9) ? 7'b1101111 :
                     (bcd_in==4'ha) ? 7'b1110111 :
                     (bcd_in==4'hb) ? 7'b1111100 :
                     (bcd_in==4'hc) ? 7'b0111001 :
                     (bcd_in==4'hd) ? 7'b1011110 :
                     (bcd_in==4'he) ? 7'b1111001 :
                     (bcd_in==4'hf) ? 7'b1110001 :
                     7'b0110110; //does a H, default shouldn't happen

endmodule
