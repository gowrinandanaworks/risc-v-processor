# Five-Stage Pipelined RISC-V Processor

An original Verilog implementation of a small 32-bit RISC-V processor, organized using the separate functional-unit folders of the reference project while adding an explicit five-stage pipeline.

> **Status:** RTL and testbench are prepared; simulation has not yet been run in this environment. Do not treat the testbench's expected PASS message as a verified result until you run it locally.

## Architecture

The processor is organized into five stages:

1. **IF — Instruction Fetch:** program counter, PC increment, instruction ROM.
2. **ID — Instruction Decode:** decoder, register-file reads, immediate generation.
3. **EX — Execute:** ALU, forwarding selection, branch comparison and target calculation.
4. **MEM — Memory Access:** word-addressed data memory for `LW` and `SW`.
5. **WB — Write Back:** writes the ALU or load result into the register file.

Pipeline state is carried between stages by the IF/ID, ID/EX, EX/MEM, and MEM/WB registers in `Processor/PROCESSOR.v`.

## Repository layout

```text
ALU/
  ALU.v
  Adder.v
Control Unit/
  CONTROL.v
Datapath/
  Datapath.v
Instruction Fetch Unit/
  IFU.v
  INST_MEM.v
Processor/
  PROCESSOR.v
  Forwarding_Unit.v
  Hazard_Detection_Unit.v
  Processor_tb.v
Register file/
  REG_FILE.v
programs/
  demo.hex
sim/
```

The folder names retain the reference project's functional-unit organization. The pipeline controller and hazard-handling units are additions for this implementation.

## Implemented instruction subset

- Register-register: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLL`, `SRL`
- Immediate: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLLI`, `SRLI`
- Memory: aligned word `LW`, `SW`
- Conditional branches: `BEQ`, `BNE`

Unsupported instructions are treated as no-ops. This is a teaching implementation of a subset of RV32I, not a complete ISA implementation.

## Pipeline hazard handling

- EX-stage forwarding from EX/MEM and MEM/WB for register operands.
- One-cycle stall for a load-use dependency.
- Branch resolution in EX, with a redirect and flush of younger instructions.
- `x0` is hardwired to zero.
- Writeback-to-read bypass in the register file.

## Tools

- Icarus Verilog (`iverilog`, `vvp`)
- GTKWave
- Vivado (add the Verilog source files and `programs/demo.hex` to the project; ensure the simulation working directory allows `$readmemh("programs/demo.hex", ...)` to resolve)

## Run the simulation

Run commands from the repository root.

### ALU unit test

```bash
iverilog -g2012 -o sim/alu_test "ALU/ALU.v" "ALU/ALU_testbench.v"
vvp sim/alu_test
```

The unit test checks arithmetic, logic, shifts, signed comparison, and the zero flag.

```bash
mkdir -p sim
iverilog -g2012 -o sim/processor.vvp \
  "ALU/Adder.v" \
  "ALU/ALU.v" \
  "Control Unit/CONTROL.v" \
  "Datapath/Datapath.v" \
  "Instruction Fetch Unit/INST_MEM.v" \
  "Instruction Fetch Unit/IFU.v" \
  "Register file/REG_FILE.v" \
  "Processor/Forwarding_Unit.v" \
  "Processor/Hazard_Detection_Unit.v" \
  "Processor/PROCESSOR.v" \
  "Processor/Processor_tb.v"
vvp sim/processor.vvp
gtkwave sim/processor.vcd
```

The testbench checks register arithmetic, a store/load round trip, a load-use dependency, and a taken branch. A successful local run should print:

```text
PASS: processor register, load/store, forwarding, stall, and branch checks.
```

If the simulation fails, debug the failing check before reporting the processor as verified.

## Demo program

`programs/demo.hex` contains instructions that:
- calculate several arithmetic/logical results,
- store and reload a value,
- create a load-use dependency,
- take a `BNE` branch to skip the `x9 = 99` instruction,
- set `x9 = 42`.

The instruction memory uses `$readmemh`, so run the simulator from the repository root.

## Reference and attribution

The functional-unit folder organization was inspired by the public repository [ash-olakangal/RISC-V-Processor](https://github.com/ash-olakangal/RISC-V-Processor). The RTL in this project has been written as a separate implementation for the five-stage pipeline; retain this attribution when publishing the project.

## Limitations and next steps

- No compressed instructions, exceptions, interrupts, CSR instructions, or full privileged architecture.
- Only aligned word loads and stores are implemented.
- No branch prediction; branches resolve in EX and flush younger instructions.
- The current testbench has not been executed in the generation environment.
- Next improvements: broaden directed tests, add random instruction tests, add assertions, and synthesize in Vivado to inspect utilization and timing.
