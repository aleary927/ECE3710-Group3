/*
* Large ROM for holding audio samples.
*/
module ROM #(parameter DATA_WIDTH, ADDR_WIDTH, INIT_FILE) 
(
  input clk, 
  input [ADDR_WIDTH - 1:0] addr, 
  output reg [DATA_WIDTH - 1:0] data
);

  reg [DATA_WIDTH - 1:0] rom [2**ADDR_WIDTH - 1:0];

  initial begin
    $readmemh(INIT_FILE, rom);
  end

  always @(negedge clk) begin 
    data <= rom[addr];
  end

endmodule
