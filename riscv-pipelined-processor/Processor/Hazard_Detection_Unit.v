// Inserts one bubble for a classic load-use dependency.
module HAZARD_DETECTION_UNIT (
    input  wire       idex_memread,
    input  wire [4:0] idex_rd,
    input  wire [31:0] ifid_instruction,
    output reg        stall
);
    wire [6:0] opcode = ifid_instruction[6:0];
    wire [4:0] ifid_rs1 = ifid_instruction[19:15];
    wire [4:0] ifid_rs2 = ifid_instruction[24:20];
    reg uses_rs1;
    reg uses_rs2;

    always @* begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        case (opcode)
            7'b0110011: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end // R-type
            7'b0010011: begin uses_rs1 = 1'b1; end                 // I-type ALU
            7'b0000011: begin uses_rs1 = 1'b1; end                 // load
            7'b0100011: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end // store
            7'b1100011: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end // branch
            default: begin uses_rs1 = 1'b0; uses_rs2 = 1'b0; end
        endcase

        stall = idex_memread && (idex_rd != 5'd0) &&
                ((uses_rs1 && (idex_rd == ifid_rs1)) ||
                 (uses_rs2 && (idex_rd == ifid_rs2)));
    end
endmodule
