// Original source can be found here: 
//`include "usb_utils.v"
`include "usb_recv.v"
`include "usb_tx.v"

module usb(
    input rst_n,
    input clk_48,
    input rx_j,
    input rx_se0,

    output tx_en,
    output tx_j,
    output tx_se0,

    input[6:0] usb_address,

    output usb_rst,

    output reg transaction_active,
    output reg[3:0] endpoint,
    output reg direction_in,
    output reg setup,
    input data_toggle,

    input[1:0] handshake,
    
    output reg[7:0] data_out,
    input[7:0] data_in,
    input data_in_valid,
    output reg data_strobe,
    output reg success
    );

localparam
    hs_ack = 2'b00,
    hs_none = 2'b01,
    hs_nak = 2'b10,
    hs_stall = 2'b11;

wire[3:0] recv_pid;
wire[7:0] recv_data;
wire recv_packet;
wire recv_datastrobe;
wire recv_crc5_ok;
wire recv_crc16_ok;
wire recv_short_idle;

usb_recv recv(
    .rst_n(rst_n),
    .clk_48(clk_48),

    .rx_j(rx_j),
    .rx_se0(rx_se0),

    .short_idle(recv_short_idle),
    .usb_rst(usb_rst),

    .xpid(recv_pid),
    .xdata(recv_data),
    .xpacket(recv_packet),
    .xdatastrobe(recv_datastrobe),
    .xcrc5_ok(recv_crc5_ok),
    .xcrc16_ok(recv_crc16_ok)
    );

reg tx_transmit;
reg[7:0] tx_data;
wire tx_data_strobe;

reg tx_enable_crc16;
wire tx_send_crc16;
usb_tx tx(
    .rst_n(rst_n),
    .clk_48(clk_48),

    .tx_en(tx_en),
    .tx_j(tx_j),
    .tx_se0(tx_se0),

    .transmit(tx_transmit),
    .data(tx_data),
    .data_strobe(tx_data_strobe),
    
    .update_crc16(tx_enable_crc16),
    .send_crc16(tx_send_crc16)
    );

reg[7:0] recv_queue_0;
reg[7:0] recv_queue_1;
reg recv_queue_0_valid;
reg recv_queue_1_valid;

always @(posedge clk_48) begin
    if (!recv_packet) begin
        recv_queue_1_valid <= 1'b0;
        recv_queue_0_valid <= 1'b0;
    end else if (recv_datastrobe) begin
        data_out <= recv_queue_1;
        recv_queue_1 <= recv_queue_0;
        recv_queue_0 <= recv_data;
        recv_queue_1_valid <= recv_queue_0_valid;
        recv_queue_0_valid <= 1'b1;
    end
end

localparam
    st_idle = 3'b000,
    st_data = 3'b001,
    st_err = 3'b010,
    st_send_handshake = 3'b011,
    st_in = 3'b100,
    st_prep_recv_ack = 3'b101,
    st_recv_ack = 3'b110,
    st_send_ack = 3'b111;

reg[2:0] state;

assign tx_send_crc16 = state == st_prep_recv_ack;

localparam
    pt_special   = 2'b00,
    pt_token     = 2'b01,
    pt_handshake = 2'b10,
    pt_data      = 2'b11;

localparam
    tok_out   = 2'b00,
    tok_sof   = 2'b01,
    tok_in    = 2'b10,
    tok_setup = 2'b11;

// Note that the token is perishable. The standard prescribes at most
// 7.5 bits of inter-packet idle time. We allow at most 31 bits between
// token activation and receiving the corresponding DATA packet.
reg[6:0] token_timeout;
wire token_active = token_timeout != 1'b0;

reg[1:0] handshake_latch;

always @(posedge clk_48 or negedge rst_n) begin
    if (!rst_n) begin
        success <= 1'b0;
        state <= st_idle;
        data_strobe <= 1'b0;
        endpoint <= 1'sbx;
        direction_in <= 1'bx;
        setup <= 1'bx;
        transaction_active <= 1'b0;
        token_timeout <= 1'b0;
        tx_transmit <= 1'b0;
        
        tx_enable_crc16 <= 1'b0;
        handshake_latch <= 2'bxx;
    end else begin
        if (token_timeout != 1'b0)
            token_timeout <= token_timeout - 1'b1;

        if (!transaction_active) begin
            endpoint <= 1'sbx;
            direction_in <= 1'bx;
            setup <= 1'bx;
            handshake_latch <= 2'bxx;
        end

        success <= 1'b0;
        data_strobe <= 1'b0;
        tx_transmit <= 1'b0;
        case (state)
            st_idle: begin
                if (!token_active)
                    transaction_active <= 1'b0;

                if (recv_packet) begin
                    if (recv_pid[1:0] == pt_token) begin
                        state <= st_data;
                    end else begin
                        if (recv_pid[1:0] == pt_data && !recv_pid[2] && token_active) begin
                            handshake_latch <= handshake;
                            state <= recv_pid[3] == data_toggle? st_data: st_send_ack;
                        end else begin
                            state <= st_err;
                        end
                    end
                end
            end
            st_data: begin
                if (!recv_packet) begin
                    state <= st_idle;
                    case (recv_pid[1:0])
                        pt_token: begin
                            if (recv_queue_1_valid && recv_crc5_ok && recv_queue_1[6:0] == usb_address && recv_pid[3:2] != tok_sof) begin
                                token_timeout <= 7'h7f;
                                transaction_active <= 1'b1;
                                endpoint <= { recv_queue_0[2:0], recv_queue_1[7] };
                                case (recv_pid[3:2])
                                    tok_in: begin
                                        direction_in <= 1'b1;
                                        setup <= 1'bx;
                                        state <= st_in;
                                    end
                                    tok_out: begin
                                        direction_in <= 1'b0;
                                        setup <= 1'b0;
                                    end
                                    tok_setup: begin
                                        direction_in <= 1'b0;
                                        setup <= 1'b1;
                                    end
                                endcase
                            end else begin
                                transaction_active <= 1'b0;
                                endpoint <= 1'sbx;
                                direction_in <= 1'bx;
                                setup <= 1'bx;
                            end
                        end
                        pt_data: begin
                            if (recv_queue_1_valid && recv_crc16_ok) begin
                                if (handshake_latch == hs_ack || handshake_latch == hs_none)
                                    success <= 1'b1;
                                state <= st_send_handshake;
                            end
                        end
                        default: begin
                            endpoint <= 1'sbx;
                            direction_in <= 1'bx;
                            setup <= 1'bx;
                        end
                    endcase
                end else if (recv_datastrobe) begin
                    case (recv_pid[1:0])
                        pt_token: begin
                            if (recv_queue_1_valid)
                                state <= st_err;
                        end
                        pt_data: begin
                            if (recv_queue_1_valid && (handshake_latch == hs_ack || handshake_latch == hs_none))
                                data_strobe <= 1'b1;
                        end
                        default: begin
                            state <= st_err;
                        end
                    endcase
                end
            end
            st_in: begin
                tx_transmit <= tx_transmit;

                if (!tx_transmit && recv_short_idle) begin
                    if (handshake != hs_ack && handshake != hs_none) begin
                        handshake_latch <= handshake;
                        state <= st_send_handshake;
                    end else begin
                        tx_data <= { !data_toggle, 3'b100, data_toggle, 3'b011 };
                        tx_transmit <= 1'b1;
                    end
                end
                
                if (tx_transmit && tx_data_strobe) begin
                    if (!data_in_valid) begin
                        if (handshake == hs_ack) begin
                            state <= st_prep_recv_ack;
                        end else begin
                            state <= st_err;
                            success <= 1'b1;
                            transaction_active <= 1'b0;
                        end
                        tx_enable_crc16 <= 1'b0;
                        tx_transmit <= 1'b0;
                    end else begin
                        tx_data <= data_in;
                        data_strobe <= 1'b1;
                        tx_enable_crc16 <= 1'b1;
                    end
                end
            end
            st_prep_recv_ack: begin
                token_timeout <= 7'h7f;
                if (!tx_en && !recv_packet)
                    state <= st_recv_ack;
            end
            st_recv_ack: begin
                if (recv_packet) begin
                    state <= st_err;
                    if (recv_pid == 4'b0010) begin
                        success <= 1'b1;
                        transaction_active <= 1'b0;
                    end
                end
                if (!token_active && !recv_packet)
                    state <= st_idle;
            end
            st_send_ack: begin
                tx_transmit <= tx_transmit;

                if (!tx_transmit && recv_short_idle) begin
                    tx_data <= 8'b11010010; // ACK
                    tx_transmit <= 1'b1;
                    
                end
                
                if (tx_transmit && tx_data_strobe) begin
                    tx_transmit <= 1'b0;
                    state <= st_err;
                end
            end
            st_send_handshake: begin
                tx_transmit <= tx_transmit;

                if (!tx_transmit && recv_short_idle) begin
                    case (handshake_latch)
                        hs_none: begin
                            state <= st_idle;
                        end
                        hs_ack: begin
                            tx_data <= 8'b11010010;
                            tx_transmit <= 1'b1;
                        end
                        hs_nak: begin
                            tx_data <= 8'b01011010;
                            tx_transmit <= 1'b1;
                        end
                        hs_stall: begin
                            tx_data <= 8'b00011110;
                            tx_transmit <= 1'b1;
                        end
                    endcase
                end
                
                if (tx_transmit && tx_data_strobe) begin
                    tx_transmit <= 1'b0;
                    state <= st_err;
                end
            end
            default: begin
                transaction_active <= 1'b0;
                if (!tx_en && !recv_packet)
                    state <= st_idle;
            end
        endcase
    end
end

endmodule