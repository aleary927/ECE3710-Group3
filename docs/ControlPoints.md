# Control Points 
This document contains a table of the control points identified within the 
CPU design.

| Module | Control Point Name  | Description |
| --------------- | --------------- | --------------- |
| ALU | select | selects the function of the ALU |
| RF | wr_en | controls whether new data is written to a register |
| RF | of_f_en | controls whether new overflow flag (C, F) values are written |
| RF | cmp_f_en | controls whether new comparision flag (N, L) values are written | 
| RF | z_f_en | controls whether a new zero flag (Z) value is written |
