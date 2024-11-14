module Counter_enabled #(parameter COUNTER_WIDTH = 16) 
(
  input clk, 
  input reset_n, 
  input en, 
  output reg [COUNTER_WIDTH - 1:0] count
); 

  always @(posedge clk) begin 
    if (!reset_n) 
      count <= 0;
    else if (en) 
      count <= count + 1'b1;
    else 
      count <= count;
  end

endmodule
