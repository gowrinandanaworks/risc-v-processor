// Immediate generator and a simple word-addressed data memory.
// Supported memory operations are aligned LW and SW.
module IMMEDIATE_GENERATOR (
    input  wire [31:0] instruction,
    output reg  [31:0] immediate
);
    wire [6:0] opcode = instruction[6:0];

    always @* begin
        case (opcode)
            7'b0010011, 7'b0000011: // I-type arithmetic and loads
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: // S-type stores
                immediate = {{20{instruction[31]}},
                             instruction[31:25], instruction[11:7]};
            7'b1100011: // B-type conditional branches
                immediate = {{19{instruction[31]}}, instruction[31],
                             instruction[7], instruction[30:25],
                             instruction[11:8], 1'b0};
            default:
                immediate = 32'b0;
        endcase
    end
endmodule

module DATA_MEMORY (
    input  wire        clock,
    input  wire        reset,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] words [0:255];
    integer index;

    initial begin
        for (index = 0; index < 256; index = index + 1)
            words[index] = 32'b0;
    end

    always @(posedge clock) begin
        if (reset) begin
            for (index = 0; index < 256; index = index + 1)
                words[index] <= 32'b0;
        end else if (mem_write && (address[1:0] == 2'b00)) begin
            words[address[9:2]] <= write_data;
        end
    end

    assign read_data = (mem_read && (address[1:0] == 2'b00))
                     ? words[address[9:2]] : 32'b0;
endmodule
