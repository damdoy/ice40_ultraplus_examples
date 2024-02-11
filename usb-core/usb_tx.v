// Original source can be found here: 
`include "usb_utils.v"
module usb_tx(
    input rst_n,
    input clk_48,

    output tx_en,
    output tx_j,
    output tx_se0,
    
    input transmit,
    input[7:0] data,
    input update_crc16,
    input send_crc16,
    output data_strobe
    );

reg[1:0] tx_clock;
wire bit_strobe = tx_clock == 2'b00;
always @(posedge clk_48 or negedge rst_n) begin
    if (!rst_n) begin
        tx_clock <= 2'b00;
    end else begin
        tx_clock <= tx_clock + 1'b1;
    end
end

wire bit_stuff;
wire tx_strobe = bit_strobe && !bit_stuff;

reg[2:0] state;
localparam
    st_idle = 3'b000,
    st_sync = 3'b101,
    st_run  = 3'b001,
    st_eop1 = 3'b010,
    st_eop2 = 3'b011,
    st_eop3 = 3'b100,
    st_crc1 = 3'b110,
    st_crc2 = 3'b111;

assign tx_en = (state != st_idle);

reg[8:0] tx_data;
reg crc_enabled;

wire dump_crc = state == st_crc1 || state == st_crc2;
wire crc_out;
wire d = dump_crc? !crc_out: tx_data[0];
wire se0 = !bit_stuff && (state == st_eop1 || state == st_eop2);

wire tx_data_empty = (tx_data[8:2] == 1'b0);
assign data_strobe = transmit && tx_data_empty && tx_strobe;

always @(posedge clk_48 or negedge rst_n) begin
    if (!rst_n) begin
        state <= st_idle;
    end else if (tx_strobe) begin
        case (state)
            st_idle: begin
                if (transmit)
                    state <= st_run;
            end
            st_sync: begin
                if (tx_data_empty)
                    state <= st_run;
            end
            st_run: begin
                if (tx_data_empty && !transmit) begin
                    if (send_crc16)
                        state <= st_crc1;
                    else
                        state <= st_eop1;
                end
            end
            st_crc1: begin
                if (tx_data_empty)
                    state <= st_crc2;
            end
            st_crc2: begin
                if (tx_data_empty)
                    state <= st_eop1;
            end
            st_eop1: begin
                state <= st_eop2;
            end
            st_eop2: begin
                state <= st_eop3;
            end
            st_eop3: begin
                state <= st_idle;
            end
        endcase
    end
end
    
always @(posedge clk_48) begin
    if (tx_strobe) begin
        if (!tx_en) begin
            tx_data <= 9'b110000000; // starting with J, go through KJKJKJKK
            crc_enabled <= 1'b0;
        end else if (tx_data_empty) begin
            tx_data <= { 1'b1, data };
            crc_enabled <= update_crc16;
        end else begin
            tx_data <= { 1'b0, tx_data[8:1] };
        end
    end
end

reg[2:0] bit_stuff_counter;
assign bit_stuff = bit_stuff_counter == 3'd6;
always @(posedge clk_48 or negedge rst_n) begin
    if (!rst_n) begin
        bit_stuff_counter <= 1'b0;
    end else if (bit_strobe) begin
        if (state == st_idle || !d || bit_stuff || se0)
            bit_stuff_counter <= 1'b0;
        else
            bit_stuff_counter <= bit_stuff_counter + 1'b1;
    end
end

reg last_j;
wire j = state == st_idle || state == st_eop3? 1'b1: ((bit_stuff || !d)? !last_j: last_j);
always @(posedge clk_48) begin
    if (bit_strobe)
        last_j <= tx_en? j: 1'b1;
end

assign tx_j = j;
assign tx_se0 = se0;

usb_crc16 tx_crc(
    .rst_n(rst_n && state != st_idle),
    .clk(clk_48),
    .clken(tx_strobe && (dump_crc || crc_enabled)),
    .d(d),
    .dump(dump_crc),
    .out(crc_out),
    .valid()
    );

endmodule