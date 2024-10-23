/*
* Module to represent memory for CR16 CPU.
*
* Reads continuously, writes on rising edge.
*/
module Memory #(parameter DATA_WIDTH = 16, SIZE = 2**16)
(
  input clk,
  input wr_en,
  input [$clog2(SIZE) - 1:0] addr, 
  input [DATA_WIDTH - 1:0] wr_data, 
  output [DATA_WIDTH - 1:0] rd_data
);

  // memory
  reg [DATA_WIDTH - 1:0] ram [SIZE - 1:0];

  // load memory
  initial begin 
    $readmemh("/path/to/file.dat", ram);
  end

  // write on rising edge of clock 
  always @(posedge clk) begin 
    // only write on wr_en 
    if (wr_en) 
      ram[addr] <= wr_data;
  end

  // continuous read
  assign rd_data = ram[addr];

endmodule
