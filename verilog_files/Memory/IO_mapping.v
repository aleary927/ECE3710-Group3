/*
* This module is to be connected to the CPU's memory port, providing it 
* with access to various peripherals.
*/
module IO_mapping(
  input clk, 
  input reset_n,

  input [15:0] mem_addr, 
  input wr_en,
  output [15:0] rd_data, 
  input [15:0] wr_data,

  input [3:0] KEY,
  input [9:0] SW, 
  output [9:0] LEDR, 
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, 
  input [3:0] drumpads,
  input [15:0] VGA_hCount, VGA_vCount, 
  output [1:0] music_ctrl,
);

  /*********************** 
  * Parameters 
  ***********************/

  localparam  SW_ADDR           = 16'hFFFF,
              KEY_ADDR          = 16'hFFFE,
              LEDR_ADDR         = 16'hFFFD,
              HEX_H_ADDR        = 16'hFFFC,
              HEX_L_ADDR        = 16'hFFFB,
              VGA_HCOUNT_ADDR   = 16'hFFFA,
              VGA_VCOUNT_ADDR   = 16'hFFF9,
              MUSIC_CTRL_ADDR   = 16'hFFF8,
              DRUMPAD_ADDR      = 16'hFFF7;

  // registers for I/O outputs 
  reg [3:0] hex0, hex1, hex2, hex3, hex4, hex5, hex6;
  reg [9:0] ledr;
  reg [1:0] music_ctrl;

  /************************** 
  * Sequential 
  **************************/

  // write to hex low
  always @(posedge clk) begin 
    // write all zeros to regs
    if (!reset_n) begin 
      hex0 <= 4'b0; 
      hex1 <= 4'b0;
      hex2 <= 4'b0; 
      hex3 <= 4'b0;
    end
    else if (mem_addr == HEX_L_ADDR && wr_en) begin 
      {hex3, hex2, hex1, hex0} <= wr_data;
    end
  end

  // write to hex high 
  always @(posedge clk) begin 
    if (!reset_n) begin 
      hex4 <= 4'b0; 
      hex5 <= 4'b0;
    end
    else if (mem_addr == HEX_H_ADDR && wr_en) begin 
      {hex5, hex4} <= wr_data[7:0];
    end
  end

  // write to leds 
  always @(posedge clk) begin 
    if (!reset_n) 
      leds <= 'b0;
    else if (mem_addr == LEDR_ADDR && wr_en) 
      leds <= wr_data[9:0];
  end

  // write to music ctrl 
  always @(posedge clk) begin 
    if (!reset_n) 
      music_ctrl <= 'b0;
    else if (mem_addr == MUSIC_CTRL_ADDR && wr_en) 
      music_ctrl <= wr_data[1:0];
  end

  /************************ 
  * Combinational 
  ************************/

  // generate read data by address
  always @(*) begin 
    case(mem_addr) 
      HEX_L_ADDR: rd_data = {hex3, hex2, hex1, hex0};
      HEX_H_ADDR: rd_data = {8'b0, hex5, hex4};
      LEDR_ADDR: rd_data = {6'b0, LEDR};
      SW_ADDR: rd_data = {6'b0, SW};
      KEY_ADDR: rd_data = {12'b0, KEY};
      DRUMPAD_ADDR: rd_data = {12'b0, drumpads};
      VGA_HCOUNT_ADDR: rd_data = {VGA_hCount};
      VGA_VCOUNT_ADDR: rd_data = {VGA_vCount};
      MUSIC_CTRL_ADDR: rd_data = {14'b0, music_ctrl};
      default: rd_data = 16'b0;
    endcase
  end

  /************************* 
  * Modules 
  *************************/

  hexTo7Seg ht7_0 (
    .SW(hex0), 
    .Hex(HEX0)
  );

  hexTo7Seg ht7_1 (
    .SW(hex1), 
    .Hex(HEX1)
  );

  hexTo7Seg ht7_2 (
    .SW(hex2), 
    .Hex(HEX2)
  );

  hexTo7Seg ht7_3 (
    .SW(hex3), 
    .Hex(HEX3)
  );

  hexTo7Seg ht7_4 (
    .SW(hex4), 
    .Hex(HEX4)
  );

  hexTo7Seg ht7_5 (
    .SW(hex4), 
    .Hex(HEX4)
  );

endmodule
