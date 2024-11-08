/*
* Highest level module for CPU. 
* Contains all internal components of CPU. 
* 
* This module is to be linked to memory in a higher level module 
* which contains the whole system.
*/
module CPU(
  input clk, 
  input reset_n,
  input [15:0] mem_rd_data,       // data read from memoery
  output mem_wr_en,               // memory write enable
  output [15:0] mem_addr,         // memory address 
  output [15:0] mem_wr_data       // data write to memory
); 

  // internal connections 
  wire [3:0] opcode, opcode_ext;
  wire cmp_result;
  wire reg_wr_en; 
  wire alu_src; 
  wire [3:0] alu_sel; 
  wire next_instr;
  wire pc_en; 
  wire instr_en; 
  wire cmp_f_en, of_f_en, z_f_en; 
  wire [1:0] pc_addr_mode;
  wire [2:0] write_back_sel; 
  wire [1:0] sign_ext_mode;


  // MODULES 
  // only the controller and datapath are contained in this module

  CPU_Controller controller(
    .clk(clk), 
    .reset_n(reset_n), 

    .opcode(opcode), 
    .opcode_ext(opcode_ext), 
    .reg_wr_en(reg_wr_en), 
    .alu_src(alu_src), 
    .alu_sel(alu_sel), 
    .next_instr(next_instr), 
    .pc_en(pc_en), 
    .instr_en(instr_en), 
    .cmp_f_en(cmp_f_en), 
    .of_f_en(of_f_en), 
    .z_f_en(z_f_en),
    .pc_addr_mode(pc_addr_mode), 
    .write_back_sel(write_back_sel), 
    .sign_ext_mode(sign_ext_mode),
    .cmp_result(cmp_result),

    .mem_wr_en(mem_wr_en) 
  );

  DataPath datapath ( 
    .clk(clk), 
    .reset_n(reset_n), 

    .wr_en(reg_wr_en), 
    .alu_src(alu_src), 
    .alu_sel(alu_sel), 
    .next_instr(next_instr), 
    .pc_en(pc_en), 
    .instr_en(instr_en), 
    .cmp_f_en(cmp_f_en), 
    .of_f_en(of_f_en), 
    .z_f_en(z_f_en), 
    .pc_addr_mode(pc_addr_mode), 
    .write_back_sel(write_back_sel), 
    .sign_ext_mode(sign_ext_mode), 
    .cmp_result(cmp_result), 
    .opcode(opcode), 
    .opcode_ext(opcode_ext), 

    .mem_rd_data(mem_rd_data), 
    .mem_wr_data(mem_wr_data), 
    .mem_addr(mem_addr) 
  );



endmodule
