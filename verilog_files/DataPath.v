/*
* Module to control the flow of data around the CPU.
* All data siganls (not including select, enable, etc. signals)
* are routed through this module.
*
* Inputs to this module are outputs from other modules of CPU.
* 
* Outputs from this module are inputs to other modules of CPU.
*/
module Datapath(
  // alu
  input alu_out, 
  output alu_a, alu_b,

  // pc alu 
  input n_pc, 
  output pc_imm,
  output c_pc, 

  // reg file 
  input reg_rd_data1, 
  input reg_rd_data2, 
  output reg_addr1, reg_addr2,
  output reg_wr_data,
  
  // proc regs 
  input psr, 
  input instr, 
  input pc,
  output instr_in, pc_in, 

  // controller 
  output OpCode, 
  output Rdest,
  output ImmHi_OpExt, ImmLo_Rsrc, 

  // memory 
  input mem_rd_data, 
  output mem_addr, 
  output mem_wr_data,

  // select signals TODO
); 

endmodule
