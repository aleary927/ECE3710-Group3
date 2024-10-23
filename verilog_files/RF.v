/*
* Register File module for CR16 CPU. 
*
* 16 general purpose registers, 1 register for processor status.
*/

module RF #(parameter DATA_WIDTH = 16, REGBITS = 4)
  (
    input clk,
    input wr_en,      // write enable
    input [DATA_WIDTH - 1:0] wr_data,
    input [REGBITS - 1:0] addr1, addr2,
    output [DATA_WIDTH - 1:0] rd_data1, rd_data2
  );

// register RAM
 reg [DATA_WIDTH-1:0] registers[2**REGBITS - 1:0];
 
  // load registers with all zeros
  integer i;
  initial begin 
    for (i = 0; i < 2**REGBITS; i = i + 1) begin
      registers[i] = 0;
    end
  end

   // dual-ported register file
   //   read two ports combinationally
   //   write to address 1 on rising clock edge
   always @(posedge clk) begin
      // write to registers only if write enabled
      if (wr_en) begin
        registers[addr1] <= wr_data;
      end

    end
	
    // continuous read
   assign rd_data1 = registers[addr1];
   assign rd_data2 = registers[addr2];
	
	
endmodule
