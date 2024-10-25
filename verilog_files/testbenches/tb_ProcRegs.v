/* 
* Testbench for verifying the ProcRegs module.
*/
module tb_ProcRegs(); 

  reg clk;
  reg reset;

  reg cmp_f_en, of_f_en, z_f_en;
  reg pc_en, instr_en;
  reg [15:0] pc_in, instr_in;
  reg C, L, F, Z, N;      // flags
  wire [15:0] psr, instr; 
  wire [20:0] pc;

  ProcRegs prs(.clk(clk),  .reset(reset),
                .cmp_f_en(cmp_f_en), .of_f_en(of_f_en), .z_f_en(z_f_en), 
                .C_in(C), .L_in(L), .F_in(F), .Z_in(Z), .N_in(N),
                .pc_en(pc_en), .instr_en(instr_en), 
                .pc_in(pc_in), .instr_in(instr_in),
                .psr(psr), .instr(instr), .pc(pc));

  // index's of flag bits in PSR register
  localparam C_IND = 0;
  localparam L_IND = 2;
  localparam F_IND = 5;
  localparam Z_IND = 6;
  localparam N_IND = 7;

  // generate clock signal
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin 
    reset = 0;
    pc_en = 0; 
    instr_en = 0;
    pc_in = 0; 
    instr_in = 0;
    cmp_f_en = 0; 
    of_f_en = 0; 
    z_f_en = 0;
    C = 0; 
    L = 0; 
    F = 0; 
    Z = 0; 
    N = 0;
  end

  initial begin
    $display("ProcRegs testbench starting");

    // =======================
    // TEST TAKING IN NEW FLAGS (PSR REG)
    // ======================= 

    // test that flags are not changed when write to flags not enabled
    C = 1;
    L = 1;
    F = 1;
    Z = 1;
    N = 1;
    cmp_f_en = 0;
    of_f_en = 0; 
    z_f_en = 0;
    #10;
    if (psr != 0) 
      $display("error: flags were written to when flag enable signals all low");

    // test that comparison flags are updated when write to flags enabled
    cmp_f_en = 1;
    #10; 
    if (!psr[L_IND] || !psr[N_IND]) 
      $display("error: comparison flags not set on cmp_f_en");

    of_f_en = 1; 
    #10; 
    if (!psr[C_IND] || !psr[F_IND])
      $display("error: overflow flags not set on of_f_en");

    z_f_en = 1; 
    #10; 
    if (!psr[Z_IND]) 
      $display("error: zero flag not set on z_f_en");

    cmp_f_en = 0; 
    of_f_en = 0; 
    z_f_en = 0;

    // ======================= 
    // TEST PC REG 
    // ======================= 

    // test not updating pc reg 
    pc_in = 16'b1111000010100011;
    pc_en = 0; 
    #10; 
    if (pc != 0) 
      $display("error: pc was written to when not enabled");

    // test updating pc
    pc_en = 1;
    #10;
    if (pc != pc_in) 
      $display("error: pc not written to when enabled");

    // test reseting
    reset = 1;
    pc_en = 0;
    #10; 
    if (pc != 0)
      $display("error: pc did not reset on reset signal (with pc_en low)");

    // write back to pc
    pc_en = 1;
    reset = 0;
    #10;

    // test reseting with pc_en high
    reset = 1;
    #10;
    if (pc != 0) 
      $display("error: pc did not reset on reset signal (with pc_en also high)");

    reset = 0; 
    
    // ====================== 
    // TEST INSTR REG 
    // ====================== 
    
    // test not updating instruction reg 
    instr_en = 0; 
    instr_in = 16'b1111000000001110;
    #10; 
    if (instr != 0) 
      $display("error: instr written to when instr_en low");

    // test updating instruction reg 
    instr_en = 1;
    #10; 
    if (instr != instr_in) 
      $display("error: instr not written to when instr_en high");
     
    $display("testbench complete");
  end

endmodule
