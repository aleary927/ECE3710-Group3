/* 
* Processor registers. (all non general purpose regisers)
* Contains PSR
*/
module ProcRegs(
  input clk, 
  input reset,
  input cmp_f_en, of_f_en, z_f_en,        // flag enables
  input C_in, L_in, F_in, Z_in, N_in,     // flag inputs
  output reg [15:0] psr              // processor status register
);


  // index's of flag bits in PSR register
  localparam C_IND = 0;
  localparam L_IND = 2;
  localparam F_IND = 5;
  localparam Z_IND = 6;
  localparam N_IND = 7;

  // initialize registers to all zeros
  initial begin 
    psr = 0; 
  end

  // write to regs
  always @(posedge clk) begin 

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

endmodule
