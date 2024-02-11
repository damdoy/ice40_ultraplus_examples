module multisample3(
    input clk,
    input in,
    output reg out
    );

reg[2:0] r;

always @(r) begin
    case (r)
        3'b000: out = 1'b0;
        3'b001: out = 1'b0;
        3'b010: out = 1'b0;
        3'b011: out = 1'b1;
        3'b100: out = 1'b0;
        3'b101: out = 1'b1;
        3'b110: out = 1'b1;
        3'b111: out = 1'b1;
    endcase
end

always @(posedge clk) begin
    r <= { r[1:0], in };
end

endmodule

//---------------------------------------------------------------------
module multisample5(
    input clk,
    input in,
    output reg out
    );

reg[4:0] r;

always @(r) begin
    case (r)
        5'b00000: out = 1'b0;
        5'b00001: out = 1'b0;
        5'b00010: out = 1'b0;
        5'b00011: out = 1'b0;
        5'b00100: out = 1'b0;
        5'b00101: out = 1'b0;
        5'b00110: out = 1'b0;
        5'b00111: out = 1'b1;
        5'b01000: out = 1'b0;
        5'b01001: out = 1'b0;
        5'b01010: out = 1'b0;
        5'b01011: out = 1'b1;
        5'b01100: out = 1'b0;
        5'b01101: out = 1'b1;
        5'b01110: out = 1'b1;
        5'b01111: out = 1'b1;
        5'b10000: out = 1'b0;
        5'b10001: out = 1'b0;
        5'b10010: out = 1'b0;
        5'b10011: out = 1'b1;
        5'b10100: out = 1'b0;
        5'b10101: out = 1'b1;
        5'b10110: out = 1'b1;
        5'b10111: out = 1'b1;
        5'b11000: out = 1'b0;
        5'b11001: out = 1'b1;
        5'b11010: out = 1'b1;
        5'b11011: out = 1'b1;
        5'b11100: out = 1'b1;
        5'b11101: out = 1'b1;
        5'b11110: out = 1'b1;
        5'b11111: out = 1'b1;
    endcase
end

always @(posedge clk) begin
    r <= { r[3:0], in };
end

endmodule

//---------------------------------------------------------------------
module nrzi_decode(
    input clk,
    input clken,
    input i,
    output o
    );

reg prev_i;
assign o = (prev_i == i);

always @(posedge clk) begin
    if (clken) begin
        prev_i <= i;
    end
end

endmodule