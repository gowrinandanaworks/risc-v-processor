// 32 x 32-bit register file with two combinational read ports.
// x0 is hardwired to zero. A writeback-to-read bypass avoids a same-cycle
// read-after-write hazard when an instruction is in Decode while another is in WB.
module REG_FILE (
    input  wire [4:0]  read_reg_num1,
    input  wire [4:0]  read_reg_num2,
    input  wire [4:0]  write_reg,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2,
    input  wire        regwrite,
    input  wire        clock,
    input  wire        reset
);
    reg [31:0] reg_memory [0:31];
    integer index;

    initial begin
        for (index = 0; index < 32; index = index + 1)
            reg_memory[index] = 32'b0;
    end

    always @(posedge clock) begin
        if (reset) begin
            for (index = 0; index < 32; index = index + 1)
                reg_memory[index] <= 32'b0;
        end else if (regwrite && (write_reg != 5'd0)) begin
            reg_memory[write_reg] <= write_data;
        end
    end

    assign read_data1 = (read_reg_num1 == 5'd0) ? 32'b0 :
                        ((regwrite && (write_reg == read_reg_num1))
                            ? write_data : reg_memory[read_reg_num1]);
    assign read_data2 = (read_reg_num2 == 5'd0) ? 32'b0 :
                        ((regwrite && (write_reg == read_reg_num2))
                            ? write_data : reg_memory[read_reg_num2]);
endmodule
