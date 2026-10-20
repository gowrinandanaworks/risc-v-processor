# Five-Stage Pipelined RISC-V Processor

A Verilog-based implementation of a 32-bit RISC-V processor inspired by the RV32I instruction set architecture. The project explores a five-stage pipelined datapath consisting of Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB).

The design incorporates instruction decoding, ALU operations, register-file access, memory operations, and branch handling. It also explores pipeline hazard detection and data forwarding to manage dependencies between instructions and improve execution efficiency.

**Tools:** Verilog HDL, Icarus Verilog, GTKWave, Vivado

**Key features**
- Five-stage pipelined processor architecture
- Instruction decoding and ALU execution
- Register-file and memory access
- Branch and jump handling
- Data forwarding and hazard detection
- Simulation and waveform analysis

**Objective:** To understand processor microarchitecture, instruction pipelining, and techniques for handling data and control hazards in RISC-V processors.
