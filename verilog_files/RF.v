/*
* Register File module for CR16 CPU. 
*
* 16 registers total, 15 general, 1 for processor state (address 15)
*/

module RF #(parameter DATA_WIDTH = 16, REGBITS = 4)
  (
    input clk,
    input wr_en, f_en,      // write enable, flag enable
    input [DATA_WIDTH - 1:0] wr_data,
    input [REGBITS - 1:0] addr1, addr2,
	  input C_in, L_in, F_in, Z_in, N_in,
    output [DATA_WIDTH - 1:0] rd_data1, rd_data2
  );

  // index of PSR register
  localparam PSR = 15;
  // index's of flag bits in PSR register
  localparam C_IND = 0;
  localparam L_IND = 2;
  localparam F_IND = 5;
  localparam Z_IND = 6;
  localparam N_IND = 7;

 reg  [DATA_WIDTH-1:0] registers[2**REGBITS - 1:0];

  // load registers with all zeros
  integer i;
  initial begin 
    for (i = 0; i < 2**REGBITS; i = i + 1) begin
      registers[i] = 0;
    end
  end

   // dual-ported register file
   //   read two ports combinationally
   //   write third port on rising edge of clock
   always @(posedge clk) begin
      // write to registers only if write enabled
      if (wr_en) begin
        // don't allow write to PSR register
        if (addr1 != PSR) begin
          registers[addr1] <= wr_data;
        end
		    // C <= C_in;
		    //   L <= L_in;
        // F <= F_in;
        // Z <= Z_in;
        // N <= N_in;
      end

      // only take in new flags if flag enable
      if (f_en) begin 
         registers[PSR][C_IND] <= C_in;
         registers[PSR][L_IND] <= L_in;
         registers[PSR][F_IND] <= F_in;
         registers[PSR][Z_IND] <= Z_in;
         registers[PSR][N_IND] <= N_in;
      end
    end
	
    // continuous read
   assign rd_data1 = registers[addr1];
   assign rd_data2 = registers[addr2];
	
	
endmodule
