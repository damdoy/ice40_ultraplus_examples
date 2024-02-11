
module usb_ep_banked(
    input clk,

    input direction_in,
    input setup,
    input success,
    input[6:0] cnt,

    output reg toggle,
    output bank_usb,
    output reg[1:0] handshake,
    output bank_in,
    output bank_out,
    output in_data_valid,

    input ctrl_dir_in,
    output reg[15:0] ctrl_rd_data,
    input[15:0] ctrl_wr_data,
    input[1:0] ctrl_wr_en
    );

localparam
    hs_ack = 2'b00,
    hs_none = 2'b01,
    hs_nak = 2'b10,
    hs_stall = 2'b11;

reg ep_setup;
reg ep_out_full;
reg ep_out_empty;
reg ep_in_empty;
reg ep_out_stall;
reg ep_in_stall;
reg ep_out_toggle;
reg ep_in_toggle;
reg ep_in_bank;
reg[6:0] ep_in_cnt_0;
reg[6:0] ep_in_cnt_1;
reg[6:0] ep_out_cnt;

assign in_data_valid = (cnt != (ep_in_toggle? ep_in_cnt_1: ep_in_cnt_0));
assign bank_usb = direction_in? ep_in_toggle: 1'b0;
assign bank_in = ep_in_bank;
assign bank_out = 1'b0;

always @(*) begin
    if (!direction_in && setup)
        toggle = 1'b0;
    else if (ep_setup)
        toggle = 1'b1;
    else if (direction_in)
        toggle = ep_in_toggle;
    else
        toggle = ep_out_toggle;
end

always @(*) begin
    if (direction_in) begin
        if (!ep_in_stall && !ep_setup && !ep_in_empty) begin
            handshake = hs_ack;
        end else if (!ep_setup && ep_in_stall) begin
            handshake = hs_stall;
        end else begin
            handshake = hs_nak;
        end
    end else begin
        if (setup || (!ep_out_stall && !ep_setup && ep_out_full)) begin
            handshake = hs_ack;
        end else if (!ep_setup && ep_out_stall) begin
            handshake = hs_stall;
        end else begin
            handshake = hs_nak;
        end
    end
end

always @(*) begin
    if (ctrl_dir_in) begin
        ctrl_rd_data[15:8] = ep_in_bank? ep_in_cnt_1: ep_in_cnt_0;
        ctrl_rd_data[7:0] = { ep_in_bank, ep_in_toggle, ep_in_stall, 1'b0, ep_in_empty, !ep_in_empty && ep_in_toggle == ep_in_bank };
    end else begin
        ctrl_rd_data[15:8] = ep_out_cnt;
        ctrl_rd_data[7:0] = { ep_out_toggle, ep_out_stall, ep_setup, ep_out_empty, ep_out_full };
    end
end

wire flush = ctrl_wr_data[5] || ctrl_wr_data[4] || ctrl_wr_data[3];

always @(posedge clk) begin
    if (success) begin
        if (direction_in) begin
            if (ep_in_toggle != ep_in_bank)
                ep_in_empty <= 1'b1;
            ep_in_toggle = !ep_in_toggle;
        end else begin
            if (setup)
                ep_setup <= 1'b1;

            ep_out_toggle = !ep_out_toggle;
            ep_out_empty <= 1'b0;
            ep_out_cnt <= cnt;
        end
    end

    if (ctrl_wr_en[1] && ctrl_dir_in) begin
        if (ep_in_bank)
            ep_in_cnt_1 <= ctrl_wr_data[14:8];
        else
            ep_in_cnt_0 <= ctrl_wr_data[14:8];
    end

    if (ctrl_wr_en[0] && ctrl_dir_in) begin
        if (ctrl_wr_data[5]) begin
            ep_in_toggle = 1'b0;
            ep_in_stall <= 1'b0;
            ep_in_bank <= 1'b0;
        end
        if (ctrl_wr_data[4]) begin
            ep_in_toggle = 1'b1;
            ep_in_stall <= 1'b0;
            ep_in_bank <= 1'b1;
        end
        if (ctrl_wr_data[3]) begin
            ep_in_stall <= 1'b1;
            ep_in_bank <= ep_in_toggle;
        end

        if (flush) begin
            ep_in_empty <= 1'b1;
        end

        if (ctrl_wr_data[0]) begin
            ep_in_empty <= 1'b0;
            ep_in_bank <= !ep_in_bank;
        end
    end

    if (ctrl_wr_en[0] && !ctrl_dir_in) begin
        if (ctrl_wr_data[5]) begin
            ep_out_toggle = 1'b0;
            ep_out_stall <= 1'b0;
        end
        if (ctrl_wr_data[4]) begin
            ep_out_toggle = 1'b1;
            ep_out_stall <= 1'b0;
        end
        if (ctrl_wr_data[3])
            ep_out_stall <= 1'b1;

        if (flush) begin
            ep_out_full <= 1'b0;
            ep_out_empty <= 1'b1;
        end

        if (ctrl_wr_data[2])
            ep_setup <= 1'b0;
        if (ctrl_wr_data[1]) begin
            ep_out_empty <= 1'b1;
            ep_out_full <= 1'b0;
        end
        if (ctrl_wr_data[0])
            ep_out_full <= 1'b1;
    end
end

endmodule