// Reusable 32-bit combinational adder for PC and branch-target arithmetic.
module RISCV_ADDER (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    output wire [31:0] sum
);
    assign sum = operand_a + operand_b;
endmodule
