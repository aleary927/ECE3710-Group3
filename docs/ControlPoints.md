# Control Points 
This document contains a table of the control points identified within the 
CPU design.

| Module | Control Point Name  | Description | 
| --------------- | --------------- | --------------- |
| DataPath | reset_n | Reset the program counter to 0 |
| DataPath | wr_en | Write enable for register file / controls whether new data is written to a register |
| DataPath | alu_src | ALU source select |
| DataPath | alu_sel | ALU function select |
| DataPath | next_instr | use PC as address to fetch next instruction |
| Memory | mem_wr_en | Memory write enable |
| DataPath | pc_en | Program counter enable |
| DataPath | instr_en | instruction register enable |
| DataPath | cmp_f_en | controls whether new comparision flag (N, L) values are written |
| DataPath | of_f_en | controls whether new overflow flag (C, F) values are written |
| DataPath | z_f_en | controls whether a new zero flag (Z) value is written |
| DataPath | pc_addr_mode | PC ALU addressing mode select |
| DataPath | write_back_sel | Select for write-back data |
