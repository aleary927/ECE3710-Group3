module RF #(parameter DATA_WIDTH, REG_BITS = 3)
  (
    input clk,
    input wr_en,
	  input [3:0] opcode,
    input [DATA_WIDTH - 1:0] wr_data,
    input [REG_BITS - 1:0] addr1, addr2,
	  input C_in, L_in, F_in, Z_in, N_in,
	  output reg C, L, F, Z, N, 
    output [DATA_WIDTH - 1:0] rd_data1, rd_data2
  );


 reg  [DATA_WIDTH-1:0] RAM [(1<<REGBITS)-1:0];
//	
//	initial begin
//	$display("Loading register file");
//	// you'll need to change the path to this file! 
//	$readmemb("<path-to-your-file>/reg.dat", RAM); 
//	$display("done with RF load"); 
//	end

   // dual-ported register file
   //   read two ports combinationally
   //   write third port on rising edge of clock
   always @(posedge clk)
      if (wr_en) begin
		    RAM[addr1] <= wr_data;
		    C <= C_in;
        L <= L_in;
        F <= F_in;
        Z <= Z_in;
        N <= N_in;
      end
	
   // register 0 is hardwired to 0
   assign rd_data1 = addr1 ? RAM[addr1] : 0;
   assign rd_data2 = addr2 ? RAM[addr2] : 0;
	
	
endmodule
