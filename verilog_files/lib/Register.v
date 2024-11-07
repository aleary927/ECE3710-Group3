/*
* Module to use for any special registers outside of register file.
*/
module Register #(parameter WIDTH = 16) 
(
  input clk, reset_n, 
  input wr_en,
  input [WIDTH - 1:0] d,
  output reg [WIDTH - 1:0] q
);

  always @(posedge clk) begin 
    if (!reset_n) 
      q <= 0;
    else if (wr_en)
      q <= d;

  end

endmodule
