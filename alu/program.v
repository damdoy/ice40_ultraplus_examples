module program(input clk,input [2:0] operation, output [2:0] alu_op);

    reg [2:0] _alu_op;

    assign alu_op = _alu_op;
    always @ (posedge clk) begin
    case (operation)
    0: _alu_op <= 0;
    1: _alu_op <= 1;
    2: _alu_op <= 2;
    3: _alu_op <= 3;
    4: _alu_op <= 4;
    5: _alu_op <= 5;
    6: _alu_op <= 6;
    7: _alu_op <= 7;
    default: _alu_op <= 0;
    endcase
    end

endmodule