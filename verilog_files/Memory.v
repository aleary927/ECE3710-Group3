/*
* Module to represent memory for CR16 CPU.
*
* Dual port, syncronous read and write.
*/
module Memory #(parameter DATA_WIDTH = 16, SIZE = 1024, MEM_FILE)
(
  input clk,
  input wr_en1, wr_en2,
  input [$clog2(SIZE) - 1:0] addr1, addr2, 
  input [DATA_WIDTH - 1:0] wr_data1, wr_data2, 
  output reg [DATA_WIDTH - 1:0] rd_data1, rd_data2
);

  // memory
  reg [DATA_WIDTH - 1:0] ram [SIZE - 1:0];

  // load memory
  integer i;
  initial begin 
    $readmemb(MEM_FILE, ram);

    // for testing only
    // for (i = 0; i < SIZE; i = i + 1) begin 
    //   ram[i] = 0;
    // end
  end

  // port 1
  always @(posedge clk) begin 
    if (wr_en1) begin
      ram[addr1] <= wr_data1;
      rd_data1 <= wr_data1;
    end
    else begin
      rd_data1 <= ram[addr1]; 
    end
  end

  // port 2
  always @(posedge clk) begin
    // port 2 
    if (wr_en2) begin
      ram[addr2] <= wr_data2;
      rd_data2 <= wr_data2;
    end
    else begin 
      rd_data2 <= ram[addr2];
    end
  end

endmodule
