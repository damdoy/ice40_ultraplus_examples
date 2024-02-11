`default_nettype none

module logic_v(input clk, input [3:0] a,input [3:0] b, input[1:0] op, output [4:0] q);
    reg [4:0] _q;
    assign q = _q;

    always @ (clk) begin
        case (op)
        0: _q <= a<<1;
        1: _q <= a>>1;
        2: _q <= ~a;
        3: _q <= a^b;
        endcase
    end

endmodule