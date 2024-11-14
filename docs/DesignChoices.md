# Design Choices 
This document contains information on the design choices made within each module 
of the design.

## Data Path 
The data path contains modules that operate on data, or control the path 
that data takes.
All data operations are within submodules, making this module purely a 
connecting module.
Each following section describes the important detals of each submodule 
contained within the DataPath module.

### Muxs 
For consistency's sake, all muxs are implemented using general purpose modules. 
There are three muxs, one for the source of the write to the register 
file, one for the ALU's b port, and one for the memory address output. 

#### Register file write mux 
This mux is 5 inputs wide. 
The inputs are as follows: 
1. result from ALU 
2. data read from memory 
3. data read from Rsrc 
4. extended immediate value 
5. current PC plus one

#### ALU source b mux 
This mux is 2 inputs wide. 
The inputs are as follows: 
1. data read from Rsrc 
2. extended immediate value

#### Memory address mux 
This mux is 2 inputs wide. 
The inputs are as follows: 
1. data read from Rsrc (Raddr in the case of LOAD and STOR) 
2. current PC


### ALU 
The ALU implements ADD, SUB, AND, OR, XOR, NOT, LSH, ASH, and MUL instructions. 
Since shift amounts are encoded as a two's complement value (positive for left, 
negative for right), the ALU takes the 
two's complement inverse of the b input and uses this as the shift amount for 
right shifts.
The ALU flags relating to overflow are calculated on ADDs and SUBs, and the 
flags relating to comparisions are only calculated on SUBs. 
The zero flag is always calculating, leaving it up to the controller to 
decide what instructions set this flag.

### Register file
The RF is written to on the rising edge of the clock, and reads combinationally.
In order to rule out any potential instability related to the combinational 
read, it may be necessary to move to a sequential read, specifically because 
there is a signal that loops back to the RF for MOV instructions.

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
value 8-bits left, and zero fills the lower bits. 
This is used for the LUI instruction.


### Comparator 
This module takes the mnemonic, which is encoded in the Rdest segment of the instruction, and uses it 
to select an expression to use to evaulate branches. 
This allows the result of a comparison instruction to be represented by a single signal, removing the 
need to examine the Rdest operand directly in the controller. 
The controller simply has to use the comparision result signal to decide upon a PC addressing mode in 
order to calculate the next instruction.

### PSR 
The processor status register is only being used to store the results from the 
ALU flags. 
The register is implemented as a full 16-bit width register as defined 
in the CR-16 architecture, this choice was deliberate to allow for easy 
expandability to include the other non-ALU flags which are not baseline. 
Additionally, this model would allow for an easy way to store the 
PSR into the register file should it be necessary for an instruction.


### PC and Instruction registers
The PC and Instruction registers are implemented using a general purpose 
16-bit register module, inspired by the Mini-MIPS design. 
The reason for this is because these registers don't have any special 
attributes like the PSR does where individual bits need to be written 
independently.

## Control FSM
The control FSM uses a 2-stage design, as the datapath design allows 
for a lot of work to be done in parallel. 
The stages of this FSM are simply fetch and execute. 

### Fetch state 
During this state, the PC is selected as the memory address, and the 
instruction register write enable is set high. 
The next instruction will be latched on the rising edge as the 
controller leaves this state. This ensures that each instruction is readily
available at the start of each execution state. 

### Execute state 
During this state, the control signals for the data path are set, 
and the result from the instruction will be stored in the 
register file (if applicable)
on the rising edge of the clock as the controller leaves this state.
Instructions such as JAL and BCOND are able to be completed in 
one state due to the added parallelism of the data path.
The comparision instructions use the comparison result signal 
from the data path to decide on a PC addressing mode which is used 
to calculate the new PC, latched as the FSM leaves this state 
and the next instruction fetch begins.
The JAL instruction is able to be completed during this cycle 
because the PC plus one signal can be stored in the register 
file while the next PC is calculated and latched into the PC 
register.
