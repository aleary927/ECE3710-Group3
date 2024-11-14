## Introduction
This document provides an in-depth overview of the design choices, 
implementation details, and considerations for developing a functional CR16-based processor. 
The primary objective of this project up to this point was to design, implement, 
and test a working processor capable of executing a defined set of baseline instructions, 
including arithmetic, logical, load/store, and branch operations, as well as jump and link instructions. 
By integrating the ALU, register file, datapath, memory interface, instruction decoding, and control FSM, 
the CPU is now able to process and execute instructions on the FPGA.

## Memory 
The memory is write on positive edge, read on negative edge.

## Memory mapped I/O 
Memory mapped I/O is implemented by simply checking the memory address and 
changing the source of the memory read data or by writing the write data to 
a register. 
If the CPU provides an address that points to I/O space, the write data will be 
written to the appropriate register if write is enabled, and 
the source of the read data to the CPU will be a register, or directly from an I/O 
device.
If the CPU attempts a write to a input I/O device, nothing will happen.

## CPU 
The CPU module simply instantiates the data path and CPU controller modules. 
It exposes memory signals, reset, and clock as ports.

## Data Path 
The data path contains modules that operate on data, or control the path 
that data takes.
All data operations are within submodules, making this module purely a 
connecting module.
Each following section describes the important detals of each submodule 
instantiated within the data path module.

### Muxs 
For consistency's sake, all muxs are implemented using general purpose modules. 
There are three muxs, one for the source of the write to the register 
file, one for the ALU's b port, and one for the memory address output. 

#### Register file write mux 
This mux is 6 inputs wide. 
The inputs are as follows: 
1. result from ALU 
2. data read from memory 
3. data read from Rsrc 
4. extended immediate value 
5. current PC plus one
6. millisecond count

#### ALU source b mux 
This mux is 2 inputs wide. 
The inputs are as follows: 
1. data read from Rsrc 
2. extended immediate value

#### Memory address mux 
This mux is 2 inputs wide. 
The inputs are as follows: 
1. data read from Rsrc 
2. current PC


### ALU 
The ALU implements ADD, SUB, AND, OR, XOR, NOT, LSH, ASH, and MUL operations. 
Since shift amounts are encoded as a two's complement value (positive for left, 
negative for right), the ALU takes the 
two's complement inverse of the b input and uses this as the shift amount when 
the b input is negative.
The ALU flags relating to overflow are calculated on ADDs and SUBs, and the 
flags relating to comparisons are only calculated on SUBs. 
The zero flag is always calculating, leaving it up to the controller to 
decide what instructions set this flag.

### Register file
The RF is written to on the rising edge of the clock, and reads combinationally.
In order to rule out any potential instability related to the combinational 
read, it may be necessary to move to a sequential read, specifically because 
there is a data path signal that loops back to the RF for the MOV instructions.

### PC ALU 
The PC ALU allows selection of a three different addressing modes for calculating the next PC. 
These modes are next instruction, offset, and absolute. 
Next instruction simply increments the PC, offset adds an immediate offset, and absolute 
jumps to an exact address.
This module also has an output signal that is always the current PC plus one. 
This signal is used for writing the PC to the register file during JAL instructions. 
The additional wire allows for the next PC to be calculated, and stored in the PC register 
at the same clock edge as the incremented current PC is stored to the register file.

### Immediate Extender 
This module is used to select from a one of three different ways to extend 
the 8-bit immediate encoded in the lower bits of the instruction to 16-bits.
These modes are sign extend, zero extend, and align high. 
The first two modes are self explanatory, and align high shifts the immediate 
value 8-bits left, zero filling the lower bits. 
This mode is used exclusively for the LUI instruction.


### Comparator 
This module takes the mnemonic, which is encoded in the Rdest segment of the 
instruction, and uses it 
to select an expression to use to evaluate branches. 
This allows the result of a comparison instruction to be represented by a single signal, 
removing the need to examine the Rdest operand directly in the controller. 
The controller simply has to use the comparison result signal to decide upon 
the PC addressing mode necessary to calculate the next instruction.

### PSR 
The processor status register is only being used to store the results from the 
ALU flags. 
The register is implemented as a full 16-bit width register as defined 
in the CR-16 architecture, this choice was deliberate to allow for easy 
expandability to include the other non-ALU flags which are not baseline. 
Additionally, this model would allow for an easy way to add a signal that allows 
the PSR to be stored into the register file should it be necessary for an instruction.

### PC and Instruction registers
The PC and Instruction registers are implemented using a general purpose 
16-bit register module, inspired by the Mini-MIPS design. 
The reason for this is because these registers don't have any special 
attributes like the PSR does where individual bits need to be written 
independently, making a purpose-built module pointless.

### Millisecond counter 
The millisecond counter is fairly self-explanatory, but the control signals are 
worth explaining.
There is a user reset, a pause signal, and a 
config enable. 
The config enable allows the pause state to be changed, by latching the pause 
signal (which is connected to the LSB of the extended immediate) into a 
register. 
The user reset resets the millisecond count, but leaves the counter that enables 
the millisecond count alone. 
This allows for the millisecond count to remain synchronized even through a reset. 
An application where this matters is counting seconds, where the CPU will check if 
the count has reached 1000 milliseconds and then reset it. 


## Control FSM
The control FSM uses a 2-state design, with fetch and execute as the 
states. 
The data path design allows for a lot of work to be done in parallel, 
enabling this design, as well as 
the memory being read on the falling edge of the clock .
The memory read had to be clocked on the falling edge of the clock due to the need to 
read data from memory, and write it to registers within one clock cycle.

### Fetch state 
During this state, the PC is selected as the memory address, and the 
instruction register write enable is set high. 
The next instruction is read from memory during the falling edge of the 
clock, ensuring that each instruction is latched at the rising edge of the 
clock as the controller enters the execution state. 
This ensures that the instruction is readily
available at the start of each execution state. 

### Execute state 
During this state, the control signals for the data path are set, 
and the result from the instruction will be stored in the 
register file (if applicable)
on the rising edge of the clock as the controller leaves this state.
Instructions such as JAL and BCOND are able to be completed in 
one state due to the added parallelism of the data path.
The comparison instructions use the comparison result signal 
from the data path to decide on a PC addressing mode which is used 
to calculate the new PC, latched as the FSM leaves this state 
and the next instruction fetch begins.
The JAL instruction is able to be completed during this cycle 
because the PC plus one signal can be stored in the register 
file while the next PC signal is latched into the PC register.

## Conclusion 
In conclusion, key design choices, like the modular structure of the datapath and the two-stage control FSM, 
allow for efficient execution by leveraging parallelism and reducing complexity in our design. 
Looking forward, the planned augmentations to integrate I/O capabilities, 
such as memory-mapped addresses for a piezo drum board and VGA display, 
will allow the CPU to interact with our planned game peripherals. 
These augmentations are designed to build upon the current framework 
without significant changes to the datapath or control logic, ensuring an efficient path for further development.

Contributions 
Hayoung: contributed by writing ALU and assembly codes

Lee: contributed by writing testbench

Aidan: 

Trae: contributed by writing the datapath, register file, and original state logic of FSM. 

