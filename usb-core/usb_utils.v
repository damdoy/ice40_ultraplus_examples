// Original source can be found here: https://github.com/avakar/usbcorev/blob/master/usb_utils.v
module usb_crc5(
    input rst_n,
    input clk,
    input clken,
    input d,
    output valid
    );

reg[4:0] r;
reg[4:0] next;

wire top = r[4];
assign valid = (next == 5'b01100);

always @(*) begin
    if (top == d)
        next = { r[3], r[2], r[1], r[0], 1'b0 };
    else
        next = { r[3], r[2], !r[1], r[0], 1'b1 };
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r <= 5'b11111;
    end else if (clken) begin
        r <= next;
    end
end

endmodule

//---------------------------------------------------------------------
module usb_crc16(
    input rst_n,
    input clk,
    input clken,
    input d,
    
    input dump,
    output out,
    output valid
    );

reg[15:0] r;
reg[15:0] next;

assign out = r[15];
assign valid = (next == 16'b1000000000001101);

always @(*) begin
    if (dump || out == d)
        next = { r[14:0], 1'b0 };
    else
        next = { !r[14], r[13:2], !r[1], r[0], 1'b1 };
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r <= 16'hffff;
    end else if (clken) begin
        r <= next;
    end
end

endmodule

//---------------------------------------------------------------------
module usb_clk_recovery(
    input rst_n,
    input clk,
    input i,
    output strobe
    );

reg[1:0] cntr;
reg prev_i;

assign strobe = cntr == 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cntr <= 1'b0;
        prev_i <= 1'b0;
    end else begin
        if (i == prev_i) begin
            cntr <= cntr - 1'b1;
        end else begin
            cntr <= 1'b1;
        end
        prev_i <= i;
    end
end

endmodule

//---------------------------------------------------------------------
module usb_bit_destuff(
    input rst_n,
    input clk,
    input clken,
    input d,
    output strobe);

reg[6:0] data;
assign strobe = clken && (data != 7'b0111111);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 7'b0000000;
    end else if (clken) begin
        data <= { data[5:0], d };
    end
end

endmodule

//---------------------------------------------------------------------
module usb_sync_detect(
    input rst_n,
    input clk,
    input clken,
    input j,
    input se0,
    output sync);

// 3KJ's followed by 2K's
reg[6:0] data;
assign sync = (data == 7'b0101010 && !j && !se0);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 1'd0;
    end else if (clken) begin
        data <= { data[5:0], j || se0 };
    end
end

endmodule

//---------------------------------------------------------------------
module usb_reset_detect(
    input rst_n,
    input clk,
    input se0,
    output usb_rst);

localparam cntr_rst_val = 19'd480000;

reg[18:0] cntr;
assign usb_rst = cntr == 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cntr <= cntr_rst_val;
    end else begin
        if (se0) begin
            if (!usb_rst)
                cntr <= cntr - 1'b1;
        end else begin
            cntr <= cntr_rst_val;
        end
    end
end

endmodule