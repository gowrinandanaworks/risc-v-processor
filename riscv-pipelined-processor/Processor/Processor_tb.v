`timescale 1ns/1ps
module PROCESSOR_TB;
    reg clock;
    reg reset;
    wire [31:0] debug_pc;
    wire debug_wb_valid;
    wire [4:0] debug_wb_rd;
    wire [31:0] debug_wb_data;

    PROCESSOR dut (
        .clock(clock),
        .reset(reset),
        .debug_pc(debug_pc),
        .debug_wb_valid(debug_wb_valid),
        .debug_wb_rd(debug_wb_rd),
        .debug_wb_data(debug_wb_data)
    );

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    initial begin
        $dumpfile("sim/processor.vcd");
        $dumpvars(0, PROCESSOR_TB);
        reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;

        // Allow the demonstration program to drain through the pipeline.
        repeat (35) @(posedge clock);
        #1;

        // Results from programs/demo.hex:
        // x1=5, x2=7, x3=12, x4=7, x5=5, x6=7,
        // memory[0]=12, x7=12, x8=17, branch skips x9=99, x9=42.
        if (dut.register_file_i.reg_memory[1] !== 32'd5)
            $fatal(1, "FAIL: x1 expected 5, got %0d", dut.register_file_i.reg_memory[1]);
        if (dut.register_file_i.reg_memory[2] !== 32'd7)
            $fatal(1, "FAIL: x2 expected 7, got %0d", dut.register_file_i.reg_memory[2]);
        if (dut.register_file_i.reg_memory[3] !== 32'd12)
            $fatal(1, "FAIL: x3 expected 12, got %0d", dut.register_file_i.reg_memory[3]);
        if (dut.register_file_i.reg_memory[4] !== 32'd7)
            $fatal(1, "FAIL: x4 expected 7, got %0d", dut.register_file_i.reg_memory[4]);
        if (dut.register_file_i.reg_memory[5] !== 32'd5)
            $fatal(1, "FAIL: x5 expected 5, got %0d", dut.register_file_i.reg_memory[5]);
        if (dut.register_file_i.reg_memory[6] !== 32'd7)
            $fatal(1, "FAIL: x6 expected 7, got %0d", dut.register_file_i.reg_memory[6]);
        if (dut.data_memory_i.words[0] !== 32'd12)
            $fatal(1, "FAIL: memory[0] expected 12, got %0d", dut.data_memory_i.words[0]);
        if (dut.register_file_i.reg_memory[7] !== 32'd12)
            $fatal(1, "FAIL: x7 expected 12, got %0d", dut.register_file_i.reg_memory[7]);
        if (dut.register_file_i.reg_memory[8] !== 32'd17)
            $fatal(1, "FAIL: x8 expected 17, got %0d", dut.register_file_i.reg_memory[8]);
        if (dut.register_file_i.reg_memory[9] !== 32'd42)
            $fatal(1, "FAIL: branch test failed; x9 expected 42, got %0d",
                   dut.register_file_i.reg_memory[9]);

        $display("PASS: processor register, load/store, forwarding, stall, and branch checks.");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "FAIL: simulation timeout");
    end
endmodule
