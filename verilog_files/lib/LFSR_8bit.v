/*
* Linear Feedback Shift Register.
*/
module LFSR_8bit
(
  input clk, 
  input reset_n, 
  input en,
  output reg [7:0] rand
);

  localparam START_BITS = 8'haa;

  wire feedback;

  always @(posedge clk) begin 
    if (!reset_n) 
      rand <= START_BITS; 
    else if (en)
      rand <= {rand[6:0], feedback};
  end

  // tap points found online: 
  // https://www.eetimes.com/tutorial-linear-feedback-shift-registers-lfsrs-part-1/
  assign feedback = rand[1] ^ rand[2] ^ rand[3] ^ rand[7]; 

endmodule
