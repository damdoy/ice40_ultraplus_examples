module RandomSeedGenerator(
    input reset,        // Reset input
    input P6,   // Start/Stop control input
    input wire [2:0] MUX3, // Frequency selection input
    output [7:0] BUS8,   // Output seed 8 bits
    output P13    // Seed ready output
);

reg [7:0] lfsr = 8'd1;       // 8-bit linear-feedback shift register (LFSR)
reg [2:0] frequency_divider = 0; // Frequency divider based on selection

reg seed_ready;
wire clk;
assign P13 = seed_ready;
assign BUS8 = seed;

//10khz used for low power applications (or sleep mode)
SB_LFOSC SB_LFOSC_inst(
    .CLKLFEN(1),
    .CLKLFPU(1),
    .CLKLF(clk)
);

// Generate random seed based on LFSR
always @(posedge clk or posedge reset) begin
    if (reset) begin
        lfsr <= 8'd1;
        seed_ready <= 0;
    end else begin
        if (P6) begin
            if (frequency_divider == 0) begin
                // Update LFSR only when frequency divider is zero
                lfsr[0] <= lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[2];
                lfsr[7:1] <= lfsr[6:0];
            end
            
            // Output seed when ready
            if (frequency_divider == 0) begin
                seed <= lfsr;
                seed_ready <= 1;
            end else begin
                seed_ready <= 0;
            end
            
            // Decrement frequency divider
            if (frequency_divider > 0)
                frequency_divider <= frequency_divider - 1;
        end
    end
end
// Update frequency divider based on selection
always @(MUX3) begin
    case (MUX3)
        3'b000: frequency_divider <= 10000; // Select frequency 1 Hz
        3'b001: frequency_divider <= 5000;  // Select frequency 2 Hz
        3'b010: frequency_divider <= 2500;  // Select frequency 4 Hz
        3'b011: frequency_divider <= 1250;  // Select frequency 8 Hz
        3'b100: frequency_divider <= 625;   // Select frequency 16 Hz
        3'b101: frequency_divider <= 312;   // Select frequency 32 Hz
        3'b110: frequency_divider <= 156;   // Select frequency 64 Hz
        3'b111: frequency_divider <= 78;    // Select frequency 128 Hz
        default: frequency_divider <= 10000; // Default to frequency 1 Hz
    endcase
end

endmodule