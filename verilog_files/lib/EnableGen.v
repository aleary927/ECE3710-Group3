/*
* Moduele to generate an enable signal for one clock cycle and roll over back to zero upon 
* reaching COUNT_TO.
*/
module EnableGen #(parameter COUNT_TO)
(
  input clk, 
  input reset_n, 
  input en,  // control the count
  output reg en_out   // output enable signal
);

  reg [$clog2(COUNT_TO - 1) - 1:0] count;

  // increment count, enable signal when count is at MAX_COUNT
  always @(posedge clk) begin
    if (!reset_n) begin
      count <= 0;
      en_out <= 0;
    end
    else if (count == (COUNT_TO - 1)) begin 
      count <= 0;
      // only set output enable signal if module enabled
      if (en) 
        en_out <= 1;
    end
    else begin 
      count <= count + 1'b1;
      en_out <= 0;
    end
  end

endmodule
