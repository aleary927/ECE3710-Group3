/*
* Module to dither a signal.
*/
module Ditherer
(
  input clk, 
  input reset_n, 
  input en,
  input [15:0] signal_in,
  output [15:0] signal_out
);

  wire [7:0] rand;

  // add sign-extended 8-bit random number
  assign signal_out = signal_in + {{8{rand[7]}}, rand};

  LFSR_8bit lfsr (
    .clk(clk), 
    .reset_n(reset_n), 
    .en(en), 
    .rand(rand)
  );


endmodule
