// Original source can be found here: 
//`include "usb_utils.v"
`include "utils.v"
module usb_recv_sm(
    input rst_n,
    input clk,
    input strobe,
    input din,
    input sync,
    input se0,
    
    output reg[3:0] xpid,
    output reg[7:0] xdata,
    output xpacket,
    output reg xdatastrobe,
    output reg xcrc5_ok,
    output reg xcrc16_ok
    );

reg clear_shift;
reg[7:0] shift_reg;
reg[8:0] next_shift;

always @(*) begin
    if (clear_shift)
        next_shift = { 7'b1, din };
    else
        next_shift = { shift_reg[7:0], din };
end

always @(posedge clk) begin
    if (strobe) begin
        shift_reg <= next_shift[7:0];
    end
end

localparam
    st_idle = 2'b00,
    st_done = 2'b10,
    st_pid = 2'b01,
    st_data = 2'b11;

reg[1:0] state;

wire crc5_valid;
usb_crc5 crc5(
    .rst_n(rst_n && xpacket),
    .clk(clk),
    .clken(strobe),
    .d(din),
    .valid(crc5_valid)
    );

wire crc16_valid;
usb_crc16 crc16(
    .rst_n(rst_n && xpacket),
    .clk(clk),
    .clken(strobe),
    .d(din),
    .dump(1'b0),
    .out(),
    .valid(crc16_valid)
    );

assign xpacket = (state == st_data);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= st_idle;
        clear_shift <= 1'bx;

        xpid <= 1'sbx;
        xdata <= 1'sbx;
        xdatastrobe <= 1'b0;
        xcrc5_ok <= 1'b0;
        xcrc16_ok <= 1'b0;
    end else if (strobe) begin
        clear_shift <= 1'bx;
        xdatastrobe <= 1'b0;

        case (state)
            st_idle: begin
                if (sync && !se0) begin
                    state <= st_pid;
                    clear_shift <= 1'b1;
                end
            end
            st_pid: begin
                if (se0) begin
                    state <= st_idle;
                end else begin
                    if (next_shift[8]) begin
                        if (next_shift[7:4] == ~next_shift[3:0]) begin
                            clear_shift <= 1'b1;
                            xpid <= { next_shift[4], next_shift[5], next_shift[6], next_shift[7] };
                            state <= st_data;
                            xcrc5_ok <= 1'b0;
                            xcrc16_ok <= 1'b0;
                        end else begin
                            state <= st_done;
                        end
                    end else begin
                        clear_shift <= 1'b0;
                    end
                end
            end
            st_data: begin
                if (se0) begin
                    state <= st_idle;
                end else begin
                    clear_shift <= 1'b0;
                    if (next_shift[8]) begin
                        clear_shift <= 1'b1;
                        xdata <= {
                            next_shift[0], next_shift[1], next_shift[2], next_shift[3],
                            next_shift[4], next_shift[5], next_shift[6], next_shift[7] };
                        xdatastrobe <= 1'b1;
                        xcrc5_ok <= crc5_valid;
                        xcrc16_ok <= crc16_valid;
                    end
                end
            end
            default: begin
                if (se0)
                    state <= st_idle;
            end
        endcase
    end
end

endmodule

module usb_recv(
    input rst_n,
    input clk_48,

    input rx_j,
    input rx_se0,

    output short_idle,
    output usb_rst,

    output[3:0] xpid,
    output[7:0] xdata,
    output xpacket,
    output xdatastrobe,
    output xcrc5_ok,
    output xcrc16_ok
    );

wire j;
multisample3 d_filter(
    .clk(clk_48),
    .in(rx_j),
    .out(j));

wire se0;
multisample5 se0_filter(
    .clk(clk_48),
    .in(rx_se0),
    .out(se0));

reg[2:0] short_idle_counter;
assign short_idle = short_idle_counter == 1'b0;
always @(posedge clk_48) begin
    if (se0 || !j || xpacket)
        short_idle_counter <= 3'b111;
    else if (short_idle_counter != 1'b0)
        short_idle_counter <= short_idle_counter - 1'b1;
end

wire nrzi_strobe;
usb_clk_recovery clk_rcvr(
    .rst_n(rst_n),
    .clk(clk_48),
    .i(j),
    .strobe(nrzi_strobe)
    );

wire d;
nrzi_decode nrzi_decoder(
    .clk(clk_48),
    .clken(nrzi_strobe),
    .i(j),
    .o(d));

wire strobe;
usb_bit_destuff destuffer(
    .rst_n(rst_n),
    .clk(clk_48),
    .clken(nrzi_strobe),
    .d(d),
    .strobe(strobe)
    );

usb_reset_detect reset_detect(
    .rst_n(rst_n),
    .clk(clk_48),
    .se0(se0),
    .usb_rst(usb_rst));

wire sync_seq;
usb_sync_detect sync_detect(
    .rst_n(rst_n),
    .clk(clk_48),
    .clken(nrzi_strobe),
    .j(j),
    .se0(se0),
    .sync(sync_seq));

wire strobed_xdatastrobe;
assign xdatastrobe = strobed_xdatastrobe && strobe;

usb_recv_sm sm(
    .rst_n(rst_n),
    .clk(clk_48),
    .strobe(strobe),
    .din(d),
    .sync(sync_seq),
    .se0(se0),
    
    .xpid(xpid),
    .xdata(xdata),
    .xpacket(xpacket),
    .xdatastrobe(strobed_xdatastrobe),
    .xcrc5_ok(xcrc5_ok),
    .xcrc16_ok(xcrc16_ok)
    );

endmodule