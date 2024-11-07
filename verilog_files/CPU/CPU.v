/*
* Highest level module for CPU. 
* Contains all internal components of CPU. 
* 
* This module is to be linked to memory in a higher level module 
* which contains the whole system.
*/
module CPU(
  input clk, 
  input [15:0] mem_rd_data,       // data read from memoery
  output mem_wr_en,               // memory write enable
  output [15:0] mem_addr,         // memory address 
  output [15:0] mem_wr_data       // data write to memory
); 

endmodule
