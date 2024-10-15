module RF #(parameter DATA_WIDTH, REG_BITS = 3)
  (
    input clk,
    input regwrite,
    input [DATA_WIDTH - 1:0] write,
    input [REG_BITS - 1:0] address1, address2,
    output [DATA_WIDTH - 1:0] read1, read2
  );



endmodule
