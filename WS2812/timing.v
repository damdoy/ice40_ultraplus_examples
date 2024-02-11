`default_nettype none

module timing(input clk, logical, output timedLogic, await);

    localparam sendonecnt = 2;
    localparam sendzerocnt = 1;

    reg [2:0] clkcnt;

    initial begin
        clkcnt = 0;
    end

    always @(posedge clk) begin

        if (logical == 1) begin
            await <= 1;
            if (clkcnt < sendonecnt + 1) begin
                timedLogic <= 1;
                clkcnt <= clkcnt + 1;
            end else begin
                timedLogic <= 0;
                clkcnt <= 0;
                await <= 0;
            end
        end else if (logical == 0) begin 
            await <= 1;
            if (clkcnt < sendonecnt + 1) begin 
                timedLogic <= 0;
                clkcnt <= clkcnt + 1;
            end else begin
                timedLogic <= 1;
                clkcnt <= 0;
                await <= 0;
            end     
        end
    end

endmodule