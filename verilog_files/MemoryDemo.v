/*
* Top-level module for on-board checkpoint 2 memory 
* demonstration.
*/
module MemoryDemo(
  input clk, 
  input reset_n,
  input next_n,
  output [6:0] rd_hex0, rd_hex1, wr_hex0, wr_hex1,
  output [9:0] leds
);

  // convert reset and next to active high
  wire reset, next;
  assign reset = ~reset_n;
  assign next = ~next_n;

  wire [15:0] wr_data, rd_data;
  wire [9:0] addr;
  wire wr_en;

  Memory mem( 
            .clk(clk), 
            .wr_en1(wr_en),
            .addr1(addr), 
            .wr_data1(wr_data),
            .rd_data1(rd_data));

  MemoryFSM fsm( 
              .clk(clk), 
              .reset(reset),
              .next(next),
              .wr_en(wr_en), 
              .data_in(rd_data), 
              .addr(addr), 
              .data_out(wr_data));

  // generate 7-seg display signals
  hexTo7Seg rd_seg0(.SW(rd_data[3:0]), .Hex(rd_hex0)); 
  hexTo7Seg rd_seg1(.SW(rd_data[7:4]), .Hex(rd_hex1)); 
  hexTo7Seg wr_seg0(.SW(wr_data[3:0]), .Hex(wr_hex0));
  hexTo7Seg wr_seg1(.SW(wr_data[7:4]), .Hex(wr_hex1));

  // output to leds
  assign leds = addr;

endmodule
