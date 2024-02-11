`default_nettype none
`timescale 10ns
`include "timing.v"

module top(input P9, P10, P11, P12, P13, output P6, LED2, LED3,LED_R, LED_G, LED_B);
    wire clk;
    reg logical;
    reg await;
    reg timedLogic;
    reg [31:0] GB_out;
    reg [23:0] i;
    reg [23:0] color;

    assign LED_R = logical;
    assign LED_G = GB_out[14];
    assign LED_B = GB_out[15];
    assign P6 = timedLogic;
    assign LED2 = timedLogic;
    assign LED3 = 0;
    SB_LFOSC SB_LFOSC_inst(
      .CLKLFEN(1),
      .CLKLFPU(1),
      .CLKLF(clk)
    );
    timing timing(.clk(clk), .logical(logical), .timedLogic(timedLogic), .await(await));

    initial begin
        logical = 0;
        i = 0;
        GB_out = 2'b00;
        color = 24'h000FF0;
    end
    always @ (posedge clk) 
    begin 

        if (await == 0) begin
            logical <= color[i];
        end 
        else begin
            GB_out <= GB_out + 1;
        end
        i <= i + 1;
    end

endmodule