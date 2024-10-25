/* 
* Processor registers. (all non general purpose regisers)
* Contains PSR, PC, INSTR registers.
*/
module ProcRegs(
  input clk, 
  input reset,
  input cmp_f_en, of_f_en, z_f_en,        // flag enables
  input pc_en, instr_en,          // enables for each special register
  input [15:0] instr_in, pc_in,
  // input cfg_en, dcr_en, dsr_en, 
  // input car_en, 
  // input isp_en, intbase_en,
  input C_in, L_in, F_in, Z_in, N_in,     // flag inputs
  // output reg [15:0] cfg, 
  // output reg [15:0] dcr, dsr, 
  // output reg [20:0] car,
  // output reg [20:0] isp, intbase,
  output reg [15:0] psr,              // processor status register
  output reg [15:0] instr,            // instruction register
  output reg [15:0] pc                // program counter
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
    instr = 0; 
    pc = 0;
  end

  // write to regs
  always @(posedge clk) begin 
    // reset by reseting program counter to 0
    if (reset) begin 
      pc <= 0;
    end
    // update pc
    else if (pc_en) 
      pc <= pc_in;

    // update instr
    if (instr_en) 
      instr <= instr_in;

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
