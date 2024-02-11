module top(inout P6, input P9, output LED2);

    reg [1:0] temp;
    assign LED2 = temp[2];
    always @(posedge clk) begin
        if (P9 == 1) begin
            temp <= temp << P6;
        end
        else begin
            P6 <= temp << 1;
        end
    end

endmodule