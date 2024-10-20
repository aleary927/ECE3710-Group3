/*
* Register File module for CR16 CPU. 
*
* 16 general purpose registers, 1 register for processor status.
*/

module RF #(parameter DATA_WIDTH = 16, REGBITS = 4)
  (
    input clk,
    input wr_en,      // write enable
    input cmp_f_en, of_f_en, z_f_en,  // comparison, overflow, and zero flag enables
    input [DATA_WIDTH - 1:0] wr_data,
    input [REGBITS - 1:0] addr1, addr2,
	  input C_in, L_in, F_in, Z_in, N_in,
    output [DATA_WIDTH - 1:0] rd_data1, rd_data2,
    output reg [15:0] psr         // processor status register
  );

  // index's of flag bits in PSR register
  localparam C_IND = 0;
  localparam L_IND = 2;
  localparam F_IND = 5;
  localparam Z_IND = 6;
  localparam N_IND = 7;

  // general registers
 reg [DATA_WIDTH-1:0] registers[2**REGBITS - 1:0];
 
  // load registers with all zeros
  integer i;
  initial begin 
    for (i = 0; i < 2**REGBITS; i = i + 1) begin
      registers[i] = 0;
    end
    psr = 0;
  end

   // dual-ported register file
   //   read two ports combinationally
   //   write third port on rising edge of clock
   always @(posedge clk) begin
      // write to registers only if write enabled
      if (wr_en) begin
        registers[addr1] <= wr_data;
      end

      // update comparison flags
      if (cmp_f_en) begin
         psr[L_IND] <= L_in;
         psr[N_IND] <= N_in;
      end
      // update overflow flags
      if (of_f_en)  begin
         psr[F_IND] <= F_in;
         psr[C_IND] <= C_in;
      end
      // update zero flag
      if (z_f_en) 
         psr[Z_IND] <= Z_in;

    end
	
    // continuous read
   assign rd_data1 = registers[addr1];
   assign rd_data2 = registers[addr2];
	
	
endmodule
