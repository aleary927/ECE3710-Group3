# Opcodes 

This document contains a list of the opcodes that we will be implementing. 

| Mnemonic  | Operands | Op Code (15-12) | Rdest (11-8) | ImmHi / Op Code Ext (7-4) | ImmLo / Rsrc (3-0) | Notes |
|---------- | -------- | --------------- | ------------ | ------------------------- | ------------------ | ----- |
| ADD       | Rsrc, Rdest       | 0000   | Rdest    | 0101      | Rsrc      |               |
| ADDI      | Imm, Rdest        | 0101   | Rdest    | ImmHi     | ImmLo     |               | 
| MUL       | Rsrc, Rdest       | 0000   | Rdest    | 1110      | Rsrc      | **not baseline**              |
| MULI      | Imm, Rdest        | 1110   | Rdest    | ImmHi     | ImmLo     | **not baseline**              |
| SUB       | Rsrc, Rdest       | 0000   | Rdest    | 1001      | Rsrc      |               | 
| SUBI      | Imm, Rdest        | 1001   | Rdest    | ImmHi     | ImmLo     |               |
| CMP       | Rsrc, Rdest       | 0000   | Rdest    | 1011      | Rsrc      |               |
| CMPI      | Imm, Rdest        | 1011   | Rdest    | ImmHi     | ImmLo     |               |
| AND       | Rsrc, Rdest       | 0000   | Rdest    | 0001      | Rsrc      |               |
| ANDI      | Imm, Rdest        | 0001   | Rdest    | ImmHi     | ImmLo     |               |
| OR        | Rsrc, Rdest       | 0000   | Rdest    | 0010      | Rsrc      |               |
| ORI       | Imm, Rdest        | 0010   | Rdest    | ImmHi     | ImmLo     |               |
| XOR       | Rsrc, Rdest       | 0000   | Rdest    | 0011      | Rsrc      |               |
| XORI      | Imm, Rdest        | 0011   | Rdest    | ImmHi     | ImmLo     |               |
| MOV       | Rsrc, Rdest       | 0000   | Rdest    | 1101      | Rsrc      |               |
| MOVI      | Imm, Rdest        | 1101   | Rdest    | ImmHi     | ImmLo     |               |
| LSH       | Ramount, Rdest    | 1000   | Rdest    | 0100      | Ramount   | n-bit              |
| LSHI      | Imm, Rdest        | 1000   | Rdest    | 000s      | ImmLo     | n-bit              |
| ASHU      | Ramount, Rdest    | 1000   | Rdest    | 0110      | Ramount   | **not baseline**              |
| ASHUI     | Imm, Rdest        | 1000   | Rdest    | 001s      | ImmLo     | **not baseline**              |
| LUI       | Imm, Rdest        | 1111   | Rdest    | ImmHi     | ImmLo     |               |
| LOAD      | Rdest, Raddr      | 0100   | Rdest    | 0000      | Raddr     |               |
| STOR      | Rsrc, Raddr       | 0100   | Rsrc     | 0100      | Raddr     |               |
| Bcond     | disp              | 1100   | cond     | DispHi    | DispLo    |               |
| Jcond     | Rtarget           | 0100   | cond     | 1100      | Rtarget   |               |
| JAL       | Rlink, Rtarget    | 0100   | Rlink    | 1000      | Rtarget   |               |


## Notes 
* This is probably an incomplete list, may add a few extra additional instructions later
