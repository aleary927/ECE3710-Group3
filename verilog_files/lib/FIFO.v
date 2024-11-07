/*
* Simple FIFO (first in first out) buffer of variable 
* data width and size.
*/
module FIFO #(parameter DATA_WIDTH = 16, SIZE_BITS = 4)
(
  input clk,
  input reset_n,
  input wr_en, 
  input rd_en, 
  input [DATA_WIDTH - 1:0] data_in, 
  output [DATA_WIDTH - 1:0] data_out, 
  output full, 
  output empty, 
  output half_full
);

  // ************************** 
  // Internal Regs, Ram, Wires
  // **************************

  reg [SIZE_BITS - 1:0] wr_ptr; 
  reg [SIZE_BITS - 1:0] rd_ptr;

  wire do_rd; 
  wire do_wr;

  reg [SIZE_BITS - 1:0] space_used;      // indicates the current amount of space used

  // wire [SIZE_BITS - 1:0] diff;

  // reg [DATA_WIDTH - 1:0] ram [2**SIZE_BITS - 1:0];

  // *************************** 
  // Sequential Logic 
  // **************************

  // read
  always @(posedge clk) begin 
    if (!reset_n)
      rd_ptr <= 0;
    else if (do_rd)
      rd_ptr <= rd_ptr + 1'b1;   // increment read pointer
    else 
      rd_ptr <= rd_ptr;
  end

  // write
  always @(posedge clk) begin 
    if (!reset_n) 
      wr_ptr <= 0;
    else if (do_wr)
      wr_ptr <= wr_ptr + 1'b1;
    else 
      wr_ptr <= wr_ptr;
  end

  // full / empty logic
  always @(posedge clk) begin 
    if (!reset_n)
      space_used <= 0;
    // read only
    else if (do_rd & !do_wr)
      space_used <= space_used - 1'b1;
    // write only
    else if (do_wr & !do_rd)
      space_used <= space_used + 1'b1;
    else 
      space_used <= space_used;
    // no change to space availble on a write and read
  end

  // ************************ 
  // Combinational
  // ***********************k

  // signals for empty and full
  // assign empty = (space_used == 0);
  // assign full = (space_used == SIZE);
  assign empty = (wr_ptr == rd_ptr); 
  assign full = ((wr_ptr + 1'b1) == rd_ptr);

  assign do_rd = rd_en & !empty;
  assign do_wr = wr_en & !full;

  // assign data_out = ram[rd_ptr];

  // half full if MSB of difference is 1
  // assign diff = wr_ptr - rd_ptr;
  // assign half_full = diff[SIZE_BITS - 1];
  assign half_full = space_used[SIZE_BITS - 1];


  // ------------------------- 
  // Modules 
  // -------------------------

  FIFO_ram #(DATA_WIDTH, SIZE_BITS) ram
  (
    .clk(clk), 
    .wr_en(do_wr), 
    .wr_addr(wr_ptr), 
    .rd_addr(rd_ptr), 
    .wr_data(data_in), 
    .rd_data(data_out)
  );


endmodule
