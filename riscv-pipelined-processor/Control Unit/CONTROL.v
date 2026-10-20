// Instruction decoder for the implemented RV32I subset.
// Unsupported encodings become no-ops by leaving all side-effect controls low.
module CONTROL (
    input  wire [31:0] instruction,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         alu_src_imm,
    output reg         branch,
    output reg  [3:0]  alu_control,
    output reg         uses_rs1,
    output reg         uses_rs2
);
    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    always @* begin
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        alu_src_imm = 1'b0;
        branch      = 1'b0;
        alu_control = 4'd0;
        uses_rs1    = 1'b0;
        uses_rs2    = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type register-register operations
                uses_rs1  = 1'b1;
                uses_rs2  = 1'b1;
                reg_write = 1'b1;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_control = 4'd1; // SUB
                        else if (funct7 == 7'b0000000)
                            alu_control = 4'd0; // ADD
                        else begin reg_write = 1'b0; alu_control = 4'd0; end
                    end
                    3'b111: alu_control = 4'd2; // AND
                    3'b110: alu_control = 4'd3; // OR
                    3'b100: alu_control = 4'd4; // XOR
                    3'b010: alu_control = 4'd5; // SLT
                    3'b001: alu_control = 4'd6; // SLL
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_control = 4'd7; // SRL
                        else begin reg_write = 1'b0; alu_control = 4'd0; end
                    end
                    default: begin reg_write = 1'b0; alu_control = 4'd0; end
                endcase
            end

            7'b0010011: begin // Immediate arithmetic/logical operations
                uses_rs1    = 1'b1;
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                case (funct3)
                    3'b000: alu_control = 4'd0; // ADDI
                    3'b111: alu_control = 4'd2; // ANDI
                    3'b110: alu_control = 4'd3; // ORI
                    3'b100: alu_control = 4'd4; // XORI
                    3'b010: alu_control = 4'd5; // SLTI
                    3'b001: alu_control = 4'd6; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_control = 4'd7; // SRLI
                        else begin reg_write = 1'b0; alu_control = 4'd0; end
                    end
                    default: begin reg_write = 1'b0; alu_control = 4'd0; end
                endcase
            end

            7'b0000011: begin // LW
                if (funct3 == 3'b010) begin
                    uses_rs1    = 1'b1;
                    reg_write   = 1'b1;
                    mem_read    = 1'b1;
                    mem_to_reg  = 1'b1;
                    alu_src_imm = 1'b1;
                    alu_control = 4'd0;
                end
            end

            7'b0100011: begin // SW
                if (funct3 == 3'b010) begin
                    uses_rs1    = 1'b1;
                    uses_rs2    = 1'b1;
                    mem_write   = 1'b1;
                    alu_src_imm = 1'b1;
                    alu_control = 4'd0;
                end
            end

            7'b1100011: begin // BEQ / BNE
                if ((funct3 == 3'b000) || (funct3 == 3'b001)) begin
                    uses_rs1    = 1'b1;
                    uses_rs2    = 1'b1;
                    branch      = 1'b1;
                    alu_control = 4'd1; // subtraction is available for debug/compare
                end
            end

            default: begin
                // Unsupported instructions act as NOPs.
            end
        endcase
    end
endmodule
