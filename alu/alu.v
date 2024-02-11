//`default_nettype none
module alu(input clk, input [3:0] a,input [3:0] b, input[2:0] op, output [4:0] q);
    reg [4:0] out;
    assign q = out;
    always @ (clk) begin
        case (op)
        0: out <= a+b;
        1: out <= ~(b-a);
        2: out <= a&b;
        3: out <= a|b;
        4: out <= a<<1;
        5: out <= a>>1;
        6: out <= ~a;
        7: out <= a^b;
        endcase
    end
endmodule