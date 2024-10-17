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
    // BASIC FLAG TESTS
    // ==============================

    // test carry
    alu_sel = ADD;
    a = 2**16 - 1;
    b = 2**16 - 1;
    #10;
    if (!C)
      $display("error: C flag not set (a = %d, b = %d)", a, b);
    // test no carry
    a = 5;
    b = 80;
    #10;
    if (C)
      $display("error: C flag set (a = %d, b = %d)", a, b);

    // test unsigned low
    alu_sel = SUB;
    a = 70;
    b = 100;
    #10;
    if (!L)
      $display("error: L flag not set (a = %d, b = %d)", a, b);
    // test no unsigned low
    b = 50;
    #10;
    if (L)
      $display("error: L flag set (a = %d, b = %d)", a, b);

    // test signed overflow
    alu_sel = ADD;
    a = -2**15;
    b = -2**15;
    #10;
    if (!F)
      $display("error: F flag not set (a = %d, b = %d)", a, b);
    // test no signed overflow
    a = -1000;
    b = -4000;
    #10;
    if (F)
      $display("error: F flag set (a = %d, b = %d)", a, b);

    // test zero result
    alu_sel = SUB;
    a = 40;
    b = 40;
    #10;
    if (!Z)
      $display("error: Z flag not set (a = %d, b = %d)", a, b);
    // test not zero result
    a = 41;
    #10;
    if (Z)
      $display("error: Z flag set (a = %d, b = %d)", a, b);

    // test signed negative result
    alu_sel = SUB;
    a = 2000;
    b = 10000;
    #10;
    if (!N)
      $display("error: N flag not set (a = %d, b = %d)", a, b);
    // test signed positive result
    b = 1000;
    #10;
    if (N)
      $display("error: N flag set (a = %d, b = %d)", a, b);


    // ======================== 
    // TEST SIGNED ARITHMETIC
    // ======================== 

    alu_sel = ADD;
    // test basic positive + positive
    a = 5; 
    b = 9;
    #10;
    if (F || N)
      $display("error: incorrect flags for signed addition (positive + positive) (expected: F=0, N=0; got: F=%d, N=%d)", F, N);
    
    // test basic positive + negative = positive
    a = 7; 
    b = -2;
    #10;
    if (F || N)
      $display("error: incorrect flags for signed addition (positive + negative = positive) (expected: F=0, N=0; got: F=%d, N=%d)", F, N);
    // test basic positive + negative = negative
    a = 14; 
    b = -40;
    #10;
    if (F || !N)
      $display("error: incorrect flags for signed addition (positive + negative = positive) (expected: F=0, N=1; got: F=%d, N=%d)", F, N);

    // test basic negative + negative
    a = -8; 
    b = -5;
    #10;
    if (F || !N)
      $display("error: incorrect flags for signed addition (negative + negative) (expected: F=0, N=1; got: F=%d, N=%d)", F, N);

    alu_sel = SUB;
    // test basic positive - positive = positive 
    a = 40; 
    b = 30;
    #10;
    if (F || N)
      $display("error: incorrect flags for signed subtraction (positive - positive = positive) (expected: F=0, N=0; got: F=%d, N=%d)", F, N);
    // test basic positive - positive = negative
    a = 99; 
    b = 105;
    #10;
    if (F || !N)
      $display("error: incorrect flags for signed subtraction (positive - positive = negative) (expected: F=0, N=1; got: F=%d, N=%d)", F, N);

    // test basic positive - negative
    a = 50; 
    b = -10;
    #10;
    if (F || N)
      $display("error: incorrect flags for signed subtraction (positive - negative) (expected: F=0, N=0; got: F=%d, N=%d)", F, N);

    // test basic negative - positive
    a = -67; 
    b = 20;
    #10;
    if (F || !N)
      $display("error: incorrect flags for signed subtraction (negative - positive) (expected: F=0, N=1; got: F=%d, N=%d)", F, N);

    // test basic negative - negative = positive 
    a = -16; 
    b = -18;
    #10;
    if (F || N)
      $display("error: incorrect flags for signed subtraction (negative - negative = positive) (expected: F=0, N=0; got: F=%d, N=%d)", F, N);

    // test basic negative - negative = negative
    a = -12; 
    b = -1;
    #10;
    if (F || !N)
      $display("error: incorrect flags for signed subtraction (negative - negative = negative) (expected: F=0, N=1; got: F=%d, N=%d)", F, N);

    // ------------------
    // OVERFLOW TESTS

    // test overflow resulting from adding 2 large positives
    alu_sel = ADD; 
    a = 2**15 - 2;
    b = 2**15 - 2;
    #10;
    if (!F || N)
      $display("error: incorrect flags for signed addition overflow with 2 positives (expected: F=1, N=0; got: F=%d, N=%d)", F, N);
    // test overflow resulting from adding 2 large negatives
    a = -2**15; 
    b = -2**15;
    #10; 
    if (!F || !N) 
      $display("error: incorrect flags for signed addition overflow with 2 negatives (expected F=1, N=1; got F=%d, N=%d)", F, N);

    // test overflow resulting from negative - positive overflow
    alu_sel = SUB; 
    a = -2**15;
    b = 2**15 - 1;
    #10; 
    if (!F || !N) 
      $display("error: incorrect flags for signed subtraction overflow (negative - positive) (expected F=1, N=1; got F=%d, N=%d)", F, N);
    // test overflow resulting from positive - negative overflow
    a = 2**15 - 1; 
    b = -2**15;
    #10; 
    if (!F || N) 
      $display("error: incorrect flags for signed subtraction overflow (positive - negative) (expected F=1, N=0; got F=%d, N=%d)", F, N);

    $display("testbench complete");
  end

endmodule
