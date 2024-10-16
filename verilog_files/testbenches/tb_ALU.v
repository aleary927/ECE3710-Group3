/*
* Testbench for verifying ALU module.
*/

module tb_ALU();

  reg [2:0] alu_sel;     // ALU function selection
  reg [15:0] a, b;        // ALU data inputs
  wire [15:0] alu_out;    // output from ALU
  wire C, L, F, Z, N;     // output flags from ALU


  // instanciate ALU and RF and link them together
  ALU alu(.a(a), .b(b), .select(alu_sel), .out(alu_out), .C(C), .L(L), .F(F), .Z(Z), .N(N));

  // parameters for ALU function selection
  parameter ADD = 3'b000;
  parameter SUB = 3'b001;
  parameter AND = 3'b010;
  parameter OR  = 3'b011;
  parameter XOR = 3'b100;

  integer res;    // result

  // instanciate inputs
  initial begin
    alu_sel = 0;
    a = 0;
    b = 0;
  end

  // main testbench code
  initial begin
    $display("ALU testbench starting...");

    // =================================
    // TEST INDIVIDUAL FUNCTIONS OF ALU
    // =================================

    // test addition
    alu_sel = ADD;
    a = 200;
    b = 3000;
    res = a + b;
    #10;
    if (alu_out != res)
      $display("error: incorrect ADD result (expected: %d, got: %d)", res, alu_out);

    // test subtraction
    alu_sel = SUB;
    a = 78;
    b = 45;
    res = a - b;
    #10;
    if (alu_out != res)
      $display("error: incorrect SUB result (expected: %d, got: %d)", res, alu_out);

    // test and
    alu_sel = AND;
    a = 16'b0000001110001010;
    b = 16'b0000001010101000;
    res = a & b;
    #10;
    if (alu_out != res)
      $display("error: incorrect AND result (expected: %d, got: %d)", res, alu_out);

    // test or
    alu_sel = OR;
    a = 16'b0001110101000111;
    b = 16'b0000100001001000;
    res = a | b;
    #10;
    if (alu_out != res)
      $display("error: incorrect OR result (expected: %d, got: %d)", res, alu_out);

    // test xor
    a = 16'b1111000010100101;
    b = 16'b1010010010011101;
    alu_sel = XOR;
    res = a ^ b;
    #10;
    if (alu_out != res)
      $display("error: incorrect XOR result (expected: %d, got: %d)", res, alu_out);

    // ==============================
    // TEST FLAGS
    // ==============================

    // test unsigned carry
    alu_sel = ADD;
    a = 2**16 - 1;
    b = 2**16 - 1;
    #10;
    if (!C)
      $display("error: C flag not set");
    // test no unsigned carry
    a = 5;
    b = 80;
    #10;
    if (C)
      $display("error: C flag set");

    // test unsigned low
    alu_sel = SUB;
    a = 70;
    b = 100;
    #10;
    if (!L)
      $display("error: L flag not set");
    // test no unsigned low
    b = 50;
    #10;
    if (L)
      $display("error: L flag set");

    // test signed overflow
    alu_sel = ADD;
    a = -2**15;
    b = -2**15;
    #10;
    if (!F)
      $display("error: F flag not set");
    // test no signed overflow
    a = -1000;
    b = -4000;
    #10;
    if (F)
      $display("error: F flag set");

    // test zero result
    alu_sel = SUB;
    a = 40;
    b = 40;
    #10;
    if (!Z)
      $display("error: Z flag not set");
    // test not zero result
    a = 41;
    #10;
    if (Z)
      $display("error: Z flag set");

    // test signed negative result
    alu_sel = SUB;
    a = 2000;
    b = 10000;
    #10;
    if (!N)
      $display("error: N flag not set");
    // test signed positive result
    b = 1000;
    #10;
    if (N)
      $display("error: N flag set");

    $display("testbench complete");
  end

endmodule
