// Selects the newest available producer value for each EX-stage source.
module FORWARDING_UNIT (
    input  wire       exmem_regwrite,
    input  wire       exmem_memread,
    input  wire [4:0] exmem_rd,
    input  wire       memwb_regwrite,
    input  wire [4:0] memwb_rd,
    input  wire [4:0] idex_rs1,
    input  wire [4:0] idex_rs2,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
    // 00 = ID/EX value, 10 = EX/MEM ALU result, 01 = MEM/WB value.
    always @* begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (exmem_regwrite && !exmem_memread && (exmem_rd != 0) &&
            (exmem_rd == idex_rs1))
            forward_a = 2'b10;
        else if (memwb_regwrite && (memwb_rd != 0) &&
                 (memwb_rd == idex_rs1))
            forward_a = 2'b01;

        if (exmem_regwrite && !exmem_memread && (exmem_rd != 0) &&
            (exmem_rd == idex_rs2))
            forward_b = 2'b10;
        else if (memwb_regwrite && (memwb_rd != 0) &&
                 (memwb_rd == idex_rs2))
            forward_b = 2'b01;
    end
endmodule
