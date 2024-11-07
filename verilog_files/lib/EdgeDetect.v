/*
* Detect rising and falling edges of an external
* clock.
*/
module EdgeDetect (
  input clk, 
  input reset_n, 
  input test_clk, 
  output rising_edge, 
  output falling_edge
);

  // last test clock
  reg last_test_clk;
  reg curr_test_clk;

  // update 
  always @(posedge clk) begin 
    if (!reset_n) begin
      last_test_clk <= 0;
      curr_test_clk <= 0;
    end
    else begin
      curr_test_clk <= test_clk;
      last_test_clk <= curr_test_clk;
    end
  end

  assign rising_edge = ~last_test_clk & curr_test_clk;
  assign falling_edge = last_test_clk & ~curr_test_clk;

endmodule
