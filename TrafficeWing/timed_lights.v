//light up the leds according to a counter to cycle through every one
`default_nettype none
module timed_lights(output P11, output P12, output P13, output P18, output P19, output P20
           , output P21, output P23, output P25, output P37, output P38, output P42
           , input P4, input P6, input P9, input P10);
    reg [31:0] counter = 0;
    reg [31:0] prevCounter = 0;
    reg [3:0] states = 0;
    reg [2:0] ryg1 = 0;
    reg [2:0] ryg2 = 0;
    reg [2:0] ryg3 = 0;
    reg [2:0] ryg4 = 0;
    wire sclk;
    assign P11 = ryg1[0];
    assign P12 = ryg1[1];
    assign P13 = ryg1[2];
    assign P18 = ryg2[2];
    assign P19 = ryg2[1];
    assign P20 = ryg2[0];
    assign P21 = ryg3[2];
    assign P23 = ryg3[1];
    assign P25 = ryg3[0];
    assign P37 = ryg4[2];
    assign P38 = ryg4[1];
    assign P42 = ryg4[0];



    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1),
        .CLKHFPU(1),
        .CLKHF(sclk)
    );

    always @ (posedge sclk)
    begin
        counter <= counter + 1;
        prevCounter <= counter[25];
        if (counter[25] & ~prevCounter)
            states <= states + 1;
        case (states)
        4'b0000: begin
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b100;
            ryg4 <= 3'b100;
        end
        4'b0001: begin
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b010;
            ryg4 <= 3'b010;
        end
        4'b0010: begin
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0011: begin
            ryg1 <= 3'b100;
            ryg3 <= 3'b100;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0100: begin
            ryg1 <= 3'b010;
            ryg3 <= 3'b010;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0101: begin
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0110: begin
            states <= 0;
        end 
        endcase
    end
   
endmodule // top
