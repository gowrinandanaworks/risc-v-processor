// Instruction Fetch Unit: program counter plus instruction memory.
// Redirect has priority over stall; reset is synchronous and active-high.
module IFU (
    input  wire        clock,
    input  wire        reset,
    input  wire        stall,
    input  wire        redirect,
    input  wire [31:0] redirect_pc,
    output reg  [31:0] pc,
    output wire [31:0] instruction
);
    wire [31:0] sequential_pc;
    RISCV_ADDER pc_increment (
        .operand_a(pc),
        .operand_b(32'd4),
        .sum(sequential_pc)
    );

    INST_MEM instruction_memory (
        .address(pc),
        .instruction(instruction)
    );

    always @(posedge clock) begin
        if (reset)
            pc <= 32'b0;
        else if (redirect)
            pc <= redirect_pc;
        else if (!stall)
            pc <= sequential_pc;
    end
endmodule
