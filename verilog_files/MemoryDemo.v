/*
* Top-level module for on-board checkpoint 2 memory 
* demonstration.
*/
module MemoryDemo(
  input clk, 
  input reset_n,
  input next_n,
  output [6:0] hex0, hex1, hex2,
  output [9:0] data
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
  hexTo7Seg seg0(.SW(addr[3:0]), .Hex(hex0)); 
  hexTo7Seg seg1(.SW(addr[7:4]), .Hex(hex1)); 
  hexTo7Seg seg2(.SW({2'b00, addr[9:8]}), .Hex(hex2));

  // output to leds
  assign data = rd_data[9:0];

endmodule
