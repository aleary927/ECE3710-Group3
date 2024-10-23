/* 
* Testbench for verifying the ProcRegs module.
*/
module tb_ProcRegs(); 

  reg clk;

  reg cmp_f_en, of_f_en, z_f_en;
  reg pc_en, instr_en;
  reg C, L, F, Z, N;      // flags
  wire [15:0] psr, instr; 
  wire [20:0] pc;

  ProcRegs prs(.clk(clk), 
                .cmp_f_en(cmp_f_en), .of_f_en(of_f_en), .z_f_en(z_f_en), 
                .C_in(C), .L_in(L), .F_in(F), .Z_in(Z), .N_in(N),
                .pc_en(pc_en), .instr_en(instr_en), 
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
    pc_en = 0; 
    instr_en = 0;
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
    if (!psr[L_IND] || !rf.psr[N_IND]) 
      $display("error: comparison flags not set on cmp_f_en");

    of_f_en = 1; 
    #10; 
    if (!psr[C_IND] || !psr[F_IND])
      $display("error: overflow flags not set on of_f_en");

    z_f_en = 1; 
    #10; 
    if (!psr[Z_IND]) 
      $display("error: zero flag not set on z_f_en");

    // ======================= 
    // TEST PC REG 
    // ======================= 
    
    // ====================== 
    // TEST INSTR REG 
    // ====================== 
     
    $display("testbench complete");
  end


endmodule
