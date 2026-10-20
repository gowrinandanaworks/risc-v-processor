// Five-stage in-order pipeline: IF, ID, EX, MEM, WB.
// Implemented subset: ADD/SUB/AND/OR/XOR/SLT/SLL/SRL, ADDI/ANDI/ORI/XORI/
// SLTI/SLLI/SRLI, LW, SW, BEQ, and BNE. Unsupported instructions act as NOPs.
module PROCESSOR (
    input  wire        clock,
    input  wire        reset,
    output wire [31:0] debug_pc,
    output wire        debug_wb_valid,
    output wire [4:0]  debug_wb_rd,
    output wire [31:0] debug_wb_data
);
    localparam [31:0] NOP = 32'h00000013;

    // IF stage
    wire [31:0] fetch_pc;
    wire [31:0] fetch_instruction;
    wire [31:0] branch_target;
    wire        stall;
    wire        branch_taken;

    IFU fetch_unit (
        .clock(clock), .reset(reset), .stall(stall),
        .redirect(branch_taken), .redirect_pc(branch_target),
        .pc(fetch_pc), .instruction(fetch_instruction)
    );
    assign debug_pc = fetch_pc;

    // IF/ID pipeline register
    reg [31:0] ifid_pc;
    reg [31:0] ifid_instruction;

    // ID stage: decode, register read, immediate generation
    wire        dec_reg_write;
    wire        dec_mem_read;
    wire        dec_mem_write;
    wire        dec_mem_to_reg;
    wire        dec_alu_src_imm;
    wire        dec_branch;
    wire [3:0]  dec_alu_control;
    wire        dec_uses_rs1;
    wire        dec_uses_rs2;
    wire [31:0] reg_data_a;
    wire [31:0] reg_data_b;
    wire [31:0] decoded_immediate;
    wire [31:0] wb_result;
    wire [4:0]  memwb_rd;
    wire        memwb_reg_write;

    CONTROL decoder (
        .instruction(ifid_instruction),
        .reg_write(dec_reg_write),
        .mem_read(dec_mem_read),
        .mem_write(dec_mem_write),
        .mem_to_reg(dec_mem_to_reg),
        .alu_src_imm(dec_alu_src_imm),
        .branch(dec_branch),
        .alu_control(dec_alu_control),
        .uses_rs1(dec_uses_rs1),
        .uses_rs2(dec_uses_rs2)
    );

    REG_FILE register_file_i (
        .read_reg_num1(ifid_instruction[19:15]),
        .read_reg_num2(ifid_instruction[24:20]),
        .write_reg(memwb_rd),
        .write_data(wb_result),
        .read_data1(reg_data_a),
        .read_data2(reg_data_b),
        .regwrite(memwb_reg_write),
        .clock(clock),
        .reset(reset)
    );

    IMMEDIATE_GENERATOR immediate_generator (
        .instruction(ifid_instruction),
        .immediate(decoded_immediate)
    );

    // ID/EX pipeline register
    reg [31:0] idex_pc;
    reg [31:0] idex_reg_a;
    reg [31:0] idex_reg_b;
    reg [31:0] idex_immediate;
    reg [4:0]  idex_rs1;
    reg [4:0]  idex_rs2;
    reg [4:0]  idex_rd;
    reg [2:0]  idex_funct3;
    reg        idex_reg_write;
    reg        idex_mem_read;
    reg        idex_mem_write;
    reg        idex_mem_to_reg;
    reg        idex_alu_src_imm;
    reg        idex_branch;
    reg [3:0]  idex_alu_control;

    HAZARD_DETECTION_UNIT hazard_unit (
        .idex_memread(idex_mem_read),
        .idex_rd(idex_rd),
        .ifid_instruction(ifid_instruction),
        .stall(stall)
    );

    // EX stage: forwarding, ALU, and branch decision
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire [31:0] exmem_alu_result;
    wire [4:0] exmem_rd;
    wire exmem_reg_write;
    wire exmem_mem_read;
    wire [31:0] memwb_mem_data;
    wire [31:0] memwb_alu_result;
    wire memwb_mem_to_reg;

    FORWARDING_UNIT forwarding_unit (
        .exmem_regwrite(exmem_reg_write),
        .exmem_memread(exmem_mem_read),
        .exmem_rd(exmem_rd),
        .memwb_regwrite(memwb_reg_write),
        .memwb_rd(memwb_rd),
        .idex_rs1(idex_rs1),
        .idex_rs2(idex_rs2),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    assign wb_result = memwb_mem_to_reg ? memwb_mem_data : memwb_alu_result;

    wire [31:0] forwarded_a =
        (forward_a == 2'b10) ? exmem_alu_result :
        (forward_a == 2'b01) ? wb_result : idex_reg_a;
    wire [31:0] forwarded_b =
        (forward_b == 2'b10) ? exmem_alu_result :
        (forward_b == 2'b01) ? wb_result : idex_reg_b;
    wire [31:0] alu_operand_b = idex_alu_src_imm ? idex_immediate : forwarded_b;
    wire [31:0] alu_result;
    wire alu_zero_unused;

    ALU execution_alu (
        .operand_a(forwarded_a),
        .operand_b(alu_operand_b),
        .alu_control(idex_alu_control),
        .alu_result(alu_result),
        .zero_flag(alu_zero_unused)
    );

    RISCV_ADDER branch_adder (
        .operand_a(idex_pc),
        .operand_b(idex_immediate),
        .sum(branch_target)
    );

    assign branch_taken = idex_branch &&
        (((idex_funct3 == 3'b000) && (forwarded_a == forwarded_b)) ||
         ((idex_funct3 == 3'b001) && (forwarded_a != forwarded_b)));

    // EX/MEM pipeline register
    reg [31:0] exmem_alu_result_reg;
    reg [31:0] exmem_store_data_reg;
    reg [4:0]  exmem_rd_reg;
    reg        exmem_reg_write_reg;
    reg        exmem_mem_read_reg;
    reg        exmem_mem_write_reg;
    reg        exmem_mem_to_reg_reg;

    assign exmem_alu_result = exmem_alu_result_reg;
    assign exmem_rd = exmem_rd_reg;
    assign exmem_reg_write = exmem_reg_write_reg;
    assign exmem_mem_read = exmem_mem_read_reg;

    // MEM stage
    wire [31:0] data_memory_read;
    DATA_MEMORY data_memory_i (
        .clock(clock),
        .reset(reset),
        .mem_read(exmem_mem_read_reg),
        .mem_write(exmem_mem_write_reg),
        .address(exmem_alu_result_reg),
        .write_data(exmem_store_data_reg),
        .read_data(data_memory_read)
    );

    // MEM/WB pipeline register
    reg [31:0] memwb_alu_result_reg;
    reg [31:0] memwb_mem_data_reg;
    reg [4:0]  memwb_rd_reg;
    reg        memwb_reg_write_reg;
    reg        memwb_mem_to_reg_reg;

    assign memwb_mem_data = memwb_mem_data_reg;
    assign memwb_alu_result = memwb_alu_result_reg;
    assign memwb_rd = memwb_rd_reg;
    assign memwb_reg_write = memwb_reg_write_reg;
    assign memwb_mem_to_reg = memwb_mem_to_reg_reg;

    assign debug_wb_valid = memwb_reg_write_reg;
    assign debug_wb_rd = memwb_rd_reg;
    assign debug_wb_data = wb_result;

    // Pipeline state updates. A taken branch flushes the two younger instructions.
    always @(posedge clock) begin
        if (reset) begin
            ifid_pc              <= 32'b0;
            ifid_instruction     <= NOP;
            idex_pc              <= 32'b0;
            idex_reg_a           <= 32'b0;
            idex_reg_b           <= 32'b0;
            idex_immediate       <= 32'b0;
            idex_rs1             <= 5'b0;
            idex_rs2             <= 5'b0;
            idex_rd              <= 5'b0;
            idex_funct3          <= 3'b0;
            idex_reg_write       <= 1'b0;
            idex_mem_read        <= 1'b0;
            idex_mem_write       <= 1'b0;
            idex_mem_to_reg      <= 1'b0;
            idex_alu_src_imm     <= 1'b0;
            idex_branch          <= 1'b0;
            idex_alu_control     <= 4'b0;
            exmem_alu_result_reg <= 32'b0;
            exmem_store_data_reg <= 32'b0;
            exmem_rd_reg         <= 5'b0;
            exmem_reg_write_reg  <= 1'b0;
            exmem_mem_read_reg   <= 1'b0;
            exmem_mem_write_reg  <= 1'b0;
            exmem_mem_to_reg_reg <= 1'b0;
            memwb_alu_result_reg <= 32'b0;
            memwb_mem_data_reg   <= 32'b0;
            memwb_rd_reg         <= 5'b0;
            memwb_reg_write_reg  <= 1'b0;
            memwb_mem_to_reg_reg <= 1'b0;
        end else begin
            // IF/ID: hold on load-use stall; clear on a taken branch.
            if (branch_taken) begin
                ifid_pc          <= 32'b0;
                ifid_instruction <= NOP;
            end else if (!stall) begin
                ifid_pc          <= fetch_pc;
                ifid_instruction <= fetch_instruction;
            end

            // ID/EX: insert a bubble on stall or flush.
            if (branch_taken || stall) begin
                idex_pc          <= 32'b0;
                idex_reg_a       <= 32'b0;
                idex_reg_b       <= 32'b0;
                idex_immediate   <= 32'b0;
                idex_rs1         <= 5'b0;
                idex_rs2         <= 5'b0;
                idex_rd          <= 5'b0;
                idex_funct3      <= 3'b0;
                idex_reg_write   <= 1'b0;
                idex_mem_read    <= 1'b0;
                idex_mem_write   <= 1'b0;
                idex_mem_to_reg  <= 1'b0;
                idex_alu_src_imm <= 1'b0;
                idex_branch      <= 1'b0;
                idex_alu_control <= 4'b0;
            end else begin
                idex_pc          <= ifid_pc;
                idex_reg_a       <= reg_data_a;
                idex_reg_b       <= reg_data_b;
                idex_immediate   <= decoded_immediate;
                idex_rs1         <= ifid_instruction[19:15];
                idex_rs2         <= ifid_instruction[24:20];
                idex_rd           <= ifid_instruction[11:7];
                idex_funct3      <= ifid_instruction[14:12];
                idex_reg_write   <= dec_reg_write;
                idex_mem_read    <= dec_mem_read;
                idex_mem_write   <= dec_mem_write;
                idex_mem_to_reg  <= dec_mem_to_reg;
                idex_alu_src_imm <= dec_alu_src_imm;
                idex_branch      <= dec_branch;
                idex_alu_control <= dec_alu_control;
            end

            // EX/MEM: current EX instruction advances even when Decode is stalled.
            exmem_alu_result_reg <= alu_result;
            exmem_store_data_reg <= forwarded_b;
            exmem_rd_reg         <= idex_rd;
            exmem_reg_write_reg  <= idex_reg_write;
            exmem_mem_read_reg   <= idex_mem_read;
            exmem_mem_write_reg  <= idex_mem_write;
            exmem_mem_to_reg_reg <= idex_mem_to_reg;

            // MEM/WB: current MEM instruction advances to Write Back.
            memwb_alu_result_reg <= exmem_alu_result_reg;
            memwb_mem_data_reg   <= data_memory_read;
            memwb_rd_reg         <= exmem_rd_reg;
            memwb_reg_write_reg  <= exmem_reg_write_reg;
            memwb_mem_to_reg_reg <= exmem_mem_to_reg_reg;
        end
    end
endmodule
