/*
* Syncronous ram with one read port and 
* one write port for use in a FIFO.
*/
module FIFO_ram #(parameter DATA_WIDTH = 16, ADDR_BITS = 5)
(
  input clk, 
  input wr_en, 
  input [ADDR_BITS - 1:0] wr_addr, 
  input [DATA_WIDTH - 1:0] wr_data,

  input [ADDR_BITS - 1:0] rd_addr, 
  output reg [DATA_WIDTH - 1:0] rd_data
);

  reg [DATA_WIDTH - 1:0] ram [2**ADDR_BITS - 1:0];

  integer i; 
  initial begin 
    for (i = 0; i < 2**ADDR_BITS; i = i + 1) begin 
      ram[i] = 0;
    end
  end

  // write port
  always @(posedge clk) begin 
    if (wr_en) 
      ram[wr_addr] <= wr_data;
  end

  // read port
  always @(posedge clk) begin 
    rd_data <= ram[rd_addr];
  end

endmodule
