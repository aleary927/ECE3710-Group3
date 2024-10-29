# Control Points 
This document contains a table of the control points identified within the 
CPU design.

| Module | Control Point Name  | Description | 
| --------------- | --------------- | --------------- |
| ALU | select | selects the function of the ALU |
| DATA_PATH | reset | Reset the program counter to 0 |
| DATA_PATH | pc_en | Program counter enable |
| instruct_reg | instr_en | instruction register enable |
| PC_ALU | addr_mode | program counter value addressing mode |
| ProcRegs | cmp_f_en | controls whether new comparision flag (N, L) values are written | 
| ProcRegs | of_f_en | controls whether new overflow flag (C, F) values are written |
| ProcRegs | z_f_en | controls whether a new zero flag (Z) value is written |
| RF | wr_en | controls whether new data is written to a register |