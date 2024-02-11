// WS2812 driver code
`default_nettype none

module ws2818(input clk, reset, input [31:0] color, input [31:0] num_leds, output [31:0] frame);
    reg s;

    integer i;
    initial begin
        for (i= 0; i < 32; i = i+1) begin
            //frame = 32'hFFFFFFFF;
            s = 0;
        end
    end

    always @ (posedge clk) begin
        if (reset) begin
            frame <= 32'h000000000;
        end
        else begin
            if (s == 0) begin
                s <= 1;
                frame <= 32'h00000000;
            end
            else begin
                for (i = 1; i < 20; i = i+1) begin
                    frame <= color;
                end
                s <= 0;
            end
        end
    end

endmodule