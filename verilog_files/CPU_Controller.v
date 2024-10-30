/*
* Control FSM for CR16 CPU.
*/
module CPU_Controller(
  input clk, 
  input reset_n, 

  // from data path
  input [3:0] opcode, opcode_ext, 
  input cmp_result,

  // to datapath 
  output reg_wr_en, 
  output alu_src, 
  output [3:0] alu_sel, 
  output next_instr,
  output pc_en, 
  output instr_en, 
  output cmp_f_en, of_f_en, z_f_en, 
  output [1:0] pc_addr_mode, 
  output [1:0] write_back_sel, 

  // to memory
  output mem_wr_en, 
); 

endmodule
