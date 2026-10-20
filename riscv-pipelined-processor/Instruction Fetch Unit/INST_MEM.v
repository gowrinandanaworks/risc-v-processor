// 256-word instruction ROM. The demo program is loaded from programs/demo.hex.
// Run simulations from the repository root so this relative path resolves.
module INST_MEM (
    input  wire [31:0] address,
    output wire [31:0] instruction
);
    reg [31:0] words [0:255];
    integer index;

    initial begin
        for (index = 0; index < 256; index = index + 1)
            words[index] = 32'h00000013; // ADDI x0,x0,0 (NOP)
        $readmemh("programs/demo.hex", words, 0, 15);
    end

    assign instruction = (address[1:0] == 2'b00)
                       ? words[address[9:2]] : 32'h00000013;
endmodule
