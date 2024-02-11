module pmem(input [3:0] addr, input wire we, clk, output [3:0] dout, input [3:0] din);
    reg [15:0] mem [0:7] /* synthesis syn_romstyle = "BRAM" */;
    integer i;
    initial begin
        for (i = 0; i < 7; i = i + 1) begin
            mem[i] = 16'h1;
        end
    end
    always @ (posedge clk) begin
        if (we)
            mem[(addr)] <= din;
    end
    assign dout = mem[addr];
endmodule