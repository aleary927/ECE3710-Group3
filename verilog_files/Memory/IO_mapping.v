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
  input song_done,
  output [2:0] music_ctrl     // (reset, hps_en, pause)
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
              DRUMPAD_ADDR      = 16'hFFF7,
              SONG_STATE_ADDR   = 16'hFFF6;

  // registers for I/O outputs 
  reg [3:0] hex0_reg, hex1_reg, hex2_reg, hex3_reg, hex4_reg, hex5_reg, hex6_reg;
  reg [9:0] ledr_reg;
  reg [2:0] music_ctrl_reg;
  reg [15:0] rd_data_reg;

  /************************** 
  * Sequential 
  **************************/

  // write to hex low
  always @(posedge clk) begin 
    // write all zeros to regs
    if (!reset_n) begin 
      hex0_reg <= 4'b0; 
      hex1_reg <= 4'b0;
      hex2_reg <= 4'b0; 
      hex3_reg <= 4'b0;
    end
    else if (mem_addr == HEX_L_ADDR && wr_en) begin 
      {hex3_reg, hex2_reg, hex1_reg, hex0_reg} <= wr_data;
    end
  end

  // write to hex high 
  always @(posedge clk) begin 
    if (!reset_n) begin 
      hex4_reg <= 4'b0; 
      hex5_reg <= 4'b0;
    end
    else if (mem_addr == HEX_H_ADDR && wr_en) begin 
      {hex5_reg, hex4_reg} <= wr_data[7:0];
    end
  end

  // write to leds 
  always @(posedge clk) begin 
    if (!reset_n) 
      ledr_reg <= 'b0;
    else if (mem_addr == LEDR_ADDR && wr_en) 
      ledr_reg <= wr_data[9:0];
  end

  // write to music ctrl 
  always @(posedge clk) begin 
    if (!reset_n) 
      music_ctrl_reg <= 'b0;
    else if (mem_addr == MUSIC_CTRL_ADDR && wr_en) 
      music_ctrl_reg <= wr_data[2:0];
  end

  /************************ 
  * Combinational 
  ************************/

  // generate read data by address
  always @(*) begin 
    case(mem_addr) 
      HEX_L_ADDR: rd_data_reg = {hex3_reg, hex2_reg, hex1_reg, hex0_reg};
      HEX_H_ADDR: rd_data_reg = {8'b0, hex5_reg, hex4_reg};
      LEDR_ADDR: rd_data_reg = {6'b0, ledr_reg};
      SW_ADDR: rd_data_reg = {6'b0, SW};
      KEY_ADDR: rd_data_reg = {12'b0, KEY};
      DRUMPAD_ADDR: rd_data_reg = {12'b0, drumpads};
      VGA_HCOUNT_ADDR: rd_data_reg = {VGA_hCount};
      VGA_VCOUNT_ADDR: rd_data_reg = {VGA_vCount};
      MUSIC_CTRL_ADDR: rd_data_reg = {13'b0, music_ctrl_reg};
      SONG_STATE_ADDR: rd_data_reg = {15'h0, song_done};
      default: rd_data_reg = 16'b0;
    endcase
  end

  assign LEDR = ledr_reg; 
  assign music_ctrl = music_ctrl_reg;
  assign rd_data = rd_data_reg;

  /************************* 
  * Modules 
  *************************/

  hexTo7Seg ht7_0 (
    .SW(hex0_reg), 
    .Hex(HEX0)
  );

  hexTo7Seg ht7_1 (
    .SW(hex1_reg), 
    .Hex(HEX1)
  );

  hexTo7Seg ht7_2 (
    .SW(hex2_reg), 
    .Hex(HEX2)
  );

  hexTo7Seg ht7_3 (
    .SW(hex3_reg), 
    .Hex(HEX3)
  );

  hexTo7Seg ht7_4 (
    .SW(hex4_reg), 
    .Hex(HEX4)
  );

  hexTo7Seg ht7_5 (
    .SW(hex5_reg), 
    .Hex(HEX5)
  );

endmodule
