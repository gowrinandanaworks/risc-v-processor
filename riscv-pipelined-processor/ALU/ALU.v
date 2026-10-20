`timescale 1ns/1ps
// Combinational ALU for the implemented RV32I subset.
// Control encoding is defined in Control Unit/CONTROL.v.
module ALU (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] alu_result,
    output wire        zero_flag
);
    always @* begin
        // A default assignment prevents inferred latches for unsupported controls.
        alu_result = 32'b0;
        case (alu_control)
            4'd0: alu_result = operand_a + operand_b;                    // ADD
            4'd1: alu_result = operand_a - operand_b;                    // SUB
            4'd2: alu_result = operand_a & operand_b;                    // AND
            4'd3: alu_result = operand_a | operand_b;                    // OR
            4'd4: alu_result = operand_a ^ operand_b;                    // XOR
            4'd5: alu_result = ($signed(operand_a) < $signed(operand_b))
                               ? 32'd1 : 32'd0;                         // SLT
            4'd6: alu_result = operand_a << operand_b[4:0];              // SLL
            4'd7: alu_result = operand_a >> operand_b[4:0];              // SRL
            default: alu_result = 32'b0;
        endcase
    end

    assign zero_flag = (alu_result == 32'b0);
endmodule
