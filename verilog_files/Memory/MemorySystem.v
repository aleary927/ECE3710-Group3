/*
* This module contains the I/O mapping and the memory itself.
*/
module MemorySystem #(parameter ADDR_BITS, MEM_FILE) 
(
  input clk, 
  input reset_n, 
    
  // peripheral inputs and outputs 
  input [3:0] KEY,
  input [9:0] SW, 
  output [9:0] LEDR, 
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
  input [3:0] drumpads,
  input [9:0] VGA_hCount, VGA_vCount, 
  output [2:0] music_ctrl,      // (reset, hps_en, pause)
  input song_done,          // from hps

  // cpu port
  input cpu_wr_en, 
  input [15:0] cpu_addr,
  input [15:0] cpu_wr_data, 
  output [15:0] cpu_rd_data,

  // second port 
  input [ADDR_BITS - 1:0] port2_addr, 
  output [15:0] port2_rd_data
); 

  wire [ADDR_BITS - 1:0] cpu_addr_ext;
  wire [15:0] cpu_rd_data_from_mem; 
  wire [15:0] cpu_rd_data_from_io;
  wire cpu_rd_data_src;     // 0 for mem, 1 for io

  // most significant 12 bits of address are 1, last 4 are don't care
  assign cpu_rd_data_src = (cpu_addr[15:4] == {12{1'b1}});

  /*************************** 
  * Modules 
  ****************************/ 

  Mux2 #(16) rd_data_mux (
   .sel(cpu_rd_data_src),
   .a(cpu_rd_data_from_mem),
   .b(cpu_rd_data_from_io),
   .out(cpu_rd_data)
  );

  IO_mapping io_mapping (
    .clk(clk), 
    .reset_n(reset_n), 
    .mem_addr(cpu_addr), 
    .wr_en(cpu_wr_en), 
    .rd_data(cpu_rd_data_from_io), 
    .wr_data(cpu_wr_data), 
    .KEY(KEY), 
    .SW(SW), 
    .LEDR(LEDR), 
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .drumpads(drumpads), 
    .music_ctrl(music_ctrl),
    .song_done(song_done),
    .VGA_vCount(VGA_vCount), 
    .VGA_hCount(VGA_hCount)
  );

  Memory #(16, 2**ADDR_BITS, MEM_FILE) mem (
    .clk(clk), 
    .wr_en1(cpu_wr_en), 
    .wr_en2(1'b0), // never written to from second port
    .addr1(cpu_addr),
    .addr2(port2_addr), 
    .wr_data1(cpu_wr_data),
    .wr_data2(16'b0),     // not writing to second port
    .rd_data1(cpu_rd_data_from_mem), 
    .rd_data2(port2_rd_data)
  );

endmodule
