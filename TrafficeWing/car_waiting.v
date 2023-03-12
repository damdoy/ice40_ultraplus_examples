// traffic light state_machine
// P4 = CAR1 | P6 = CAR3 | P9 = CAR4 | P10 = CAR2
// LANE13 is cars 1 & 2
// LANE24 is cars 2 & 4
// LANE1 Lights P11 = RED | P12 = YELLOW | P13 = GREEN
// LANE2 Lights P20 = RED | P19 = YELLOW | P18 = GREEN 
// LANE3 Lights P25 = RED | P23 = YELLOW | P21 = GREEN 
// LANE4 Lights P42 = RED | P38 = YELLOW | P37 = GREEN
//light up the leds according to a counter and button inputs to cycle through every one
`default_nettype none
module car_waiting(output P11, output P12, output P13, output P18, output P19, output P20
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
        // Check for cars on lanes 1 and 2
        if (counter[25] & ~prevCounter && (P4 | P10) && states == 4'b0000)
            states <= 4'b0001;
        // Check for cards on lanes 3 and 4
        if (counter[25] & ~prevCounter && (P6 | P9) && states == 4'b0011)
            states <= 4'b0100;
        // the following just change light states for the lanes based on the previous state.
        if (counter[25] & ~prevCounter && states == 4'b0001)
            states <= states + 1;
        if (counter[25] & ~prevCounter && states == 4'b0010)
            states <= states + 1;
        if (counter[25] & ~prevCounter && states == 4'b0100)
            states <= states + 1;
        if (counter[25] & ~prevCounter && states == 4'b0101)
            states <= states + 1;
        case (states)
        4'b0000: begin // lanes 2 and 4 green
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b100;
            ryg4 <= 3'b100;
        end
        4'b0001: begin // lanes 2 and 4 yellow
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b010;
            ryg4 <= 3'b010;
        end
        4'b0010: begin // all lanes red
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0011: begin // lanes 1 and 3 green
            ryg1 <= 3'b100;
            ryg3 <= 3'b100;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0100: begin // lanes 1 and 3 yellow
            ryg1 <= 3'b010;
            ryg3 <= 3'b010;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0101: begin // all lanes red
            ryg1 <= 3'b001;
            ryg3 <= 3'b001;
            ryg2 <= 3'b001;
            ryg4 <= 3'b001;
        end
        4'b0110: begin // restart state machine
            states <= 0;
        end 
        endcase
    end
   
endmodule // top
