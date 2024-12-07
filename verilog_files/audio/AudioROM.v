/*
* Module to link together 2 blocks of ram of size 2^16, and an additional one
* of size 2^15.
*
* The output data is selected from a rom via the two MSBs of the input addr.
*/
module AudioROM #(SAMPLE0_FILE, SAMPLE1_2_FILE) //, SAMPLE3_FILE) 
(
  input clk, 
  input [17:0] addr, 
  output [15:0] data
);

  localparam DATA_WIDTH = 16; 
  localparam ADDR_WIDTH = 16; 
  localparam SMALLROM_ADDR_WIDTH = 15;

  // data from each rom
  wire [DATA_WIDTH - 1:0] rom0_data, rom1_data, rom_small_data;

  wire [ADDR_WIDTH - 1:0] rom_addr;
  wire [SMALLROM_ADDR_WIDTH - 1:0] rom_small_addr;

  wire rom_sel;

  assign rom_sel = addr[16];

  assign rom_addr = addr[ADDR_WIDTH - 1:0];
  assign rom_small_addr = addr[SMALLROM_ADDR_WIDTH - 1:0];

  assign data = rom_sel ? rom1_data : rom0_data;

  /*************************** 
  * Modules 
  ****************************/

  ROM #(DATA_WIDTH, ADDR_WIDTH, SAMPLE0_FILE) rom0 (
    .clk(clk), 
    .addr(rom_addr), 
    .data(rom0_data)
  );

  ROM #(DATA_WIDTH, ADDR_WIDTH - 1, SAMPLE1_2_FILE) rom1 (
    .clk(clk), 
    .addr(rom_addr[ADDR_WIDTH - 2:0]), 
    .data(rom1_data)
  );

endmodule
