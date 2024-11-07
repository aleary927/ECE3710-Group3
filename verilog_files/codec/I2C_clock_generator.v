/*
* This module generates a standard slow clock signal, 
* and also generates signals for a single system 
* clock period when the clock is halfway through 
* high and low.
*/

module I2C_clock_generator #(parameter COUNTER_WIDTH = 10) 
(
  input clk, 
  input reset_n, 
  output reg slw_clk, 
  output reg middle_of_high, 
  output reg middle_of_low
);

  reg [COUNTER_WIDTH - 1:0] clk_count;

  // increment count
  always @(posedge clk) begin 
    if (!reset_n) 
      clk_count <= 0;
    else 
      clk_count <= clk_count + 1'b1;
  end

  // generate slw_clk
  always @(posedge clk) begin 
    if (!reset_n) 
      slw_clk <= 0;
    // slw_clk is MSB of counter
    else 
      slw_clk <= clk_count[COUNTER_WIDTH - 1];
  end

  // generate middle_of_high
  always @(posedge clk) begin 
    if (!reset_n) 
      middle_of_high <= 0;
    // set high on MSB high, next bit low, rest high
    else 
      middle_of_high <= clk_count[COUNTER_WIDTH - 1] & 
                        ~clk_count[COUNTER_WIDTH - 2] & 
                        (&(clk_count[COUNTER_WIDTH - 3:0]));

  end

  // gnerate middle_of_low
  always @(posedge clk) begin 

    if (!reset_n)
      middle_of_low <= 0;
    // set high if MSB and next low, rest high
    else 
      middle_of_low <= ~clk_count[COUNTER_WIDTH - 1] & 
                        ~clk_count[COUNTER_WIDTH - 2] & 
                        (&(clk_count[COUNTER_WIDTH - 3:0]));
  end

endmodule
