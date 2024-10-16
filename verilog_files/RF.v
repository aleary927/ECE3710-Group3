module RF #(parameter DATA_WIDTH, REG_BITS = 3)
  (
    input clk,
    input wr_en,
    input [DATA_WIDTH - 1:0] wr_data,
    input [REG_BITS - 1:0] addr1, addr2,
    output [DATA_WIDTH - 1:0] rd_data1, rd_data2
  );



endmodule
