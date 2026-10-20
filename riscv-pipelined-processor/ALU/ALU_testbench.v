`timescale 1ns/1ps
module ALU_TESTBENCH;
    reg [31:0] a, b;
    reg [3:0] control;
    wire [31:0] result;
    wire zero;

    ALU dut (
        .operand_a(a), .operand_b(b), .alu_control(control),
        .alu_result(result), .zero_flag(zero)
    );

    initial begin
        a = 32'd12; b = 32'd5; control = 4'd0; #1;
        if (result !== 32'd17) $fatal(1, "ADD failed");

        control = 4'd1; #1;
        if (result !== 32'd7) $fatal(1, "SUB failed");

        control = 4'd2; #1;
        if (result !== 32'd4) $fatal(1, "AND failed");

        control = 4'd3; #1;
        if (result !== 32'd13) $fatal(1, "OR failed");

        control = 4'd4; #1;
        if (result !== 32'd9) $fatal(1, "XOR failed");

        a = -32'sd2; b = 32'd1; control = 4'd5; #1;
        if (result !== 32'd1) $fatal(1, "Signed SLT failed");

        a = 32'd1; b = 32'd3; control = 4'd6; #1;
        if (result !== 32'd8) $fatal(1, "SLL failed");

        a = 32'd32; b = 32'd2; control = 4'd7; #1;
        if (result !== 32'd8) $fatal(1, "SRL failed");

        a = 32'd7; b = 32'd7; control = 4'd1; #1;
        if (!zero) $fatal(1, "Zero flag failed");

        $display("PASS: ALU arithmetic, logic, shifts, signed compare, and zero flag.");
        $finish;
    end
endmodule
