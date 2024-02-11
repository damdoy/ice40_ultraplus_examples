//`default_nettype none
`include "alu.v"
`include "pmem.v"
`include "program.v"
module top(input P4,P6,P9,P10, P11,P12,P13,P18, P19,P20,P21, P23, P37,P38,P42,P43,P44,P45,P46,P47, output LED2,LED3,LED_R,LED_G,LED_B);

    reg [4:0] q;
    wire clk;
    reg [3:0] a_addr = {P4,P6,P9,P10};
    reg [3:0] b_addr = {P11,P12,P13,P18};
    reg [3:0] addr;
    reg [3:0] din;
    reg [3:0] dout;
    reg [3:0] a;
    reg [3:0] b;
    reg [2:0] oper = {P19,P20,P21};
    reg we = P23;
    assign LED2 = q[0];
    assign LED3 = q[1];
    assign LED_R = q[2];
    assign LED_G = q[3];
    assign LED_B = q[4];

    SB_LFOSC SB_LFOSC_inst(
        .CLKLFEN(1),
        .CLKLFPU(1),
        .CLKLF(clk)
    );
    pmem mem(.addr(addr),.we(we),.clk(clk),.dout(dout),.din(din));
    program program(.clk(clk),.operation(oper),.alu_op(alu_op));
    alu alu(.clk(clk),.a(a),.b(b),.op(oper),.q(q));
    always @ (posedge clk) begin
        if (we & clk) begin 
            addr <= a_addr;
            din <= q[3:0];
        end
        else begin
            addr <= a_addr;
            a <= dout;
            addr <= b_addr;
            b <= dout;
        end
        
    end
endmodule