/*
* Linear Feedback Shift Register.
*/
module LFSR_8bit
(
  input clk, 
  input reset_n, 
  input en,
  output reg [7:0] random
);

  localparam START_BITS = 8'haa;

  wire feedback;

  always @(posedge clk) begin 
    if (!reset_n) 
      random <= START_BITS; 
    else if (en)
      random <= {random[6:0], feedback};
  end

  // tap points found online: 
  // https://www.eetimes.com/tutorial-linear-feedback-shift-registers-lfsrs-part-1/
  assign feedback = random[1] ^ random[2] ^ random[3] ^ random[7]; 

endmodule
