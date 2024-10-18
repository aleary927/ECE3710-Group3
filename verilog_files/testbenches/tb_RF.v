/*
* Testbench for verifying RF (register file) module.
*/

module tb_RF();

  reg clk;

  reg [3:0] addr1, addr2; // addresses
  reg wr_en, f_en;           // write enable
  reg [15:0] wr_data;    // write data
  reg C, L, F, Z, N;      // flags
  wire [15:0] rd_data1, rd_data2; // read data

  RF rf(.clk(clk), .wr_en(wr_en), .f_en(f_en), .wr_data(wr_data), .addr1(addr1), .addr2(addr2), .rd_data1(rd_data1), .rd_data2(rd_data2), .C_in(C), .L_in(L), .F_in(F), .Z_in(Z), .N_in(N));
  
  // index of PSR register
  localparam PSR = 15;
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

  // instanciate inputs
  initial begin
    addr1 = 0;
    addr2 = 0;
    wr_data = 0;
    wr_en = 0;
    f_en = 0;
    C = 0; 
    L = 0; 
    F = 0; 
    Z = 0; 
    N = 0; 
  end

  // main testbench code
  initial begin
    $display("Starting testbench for RF (register file)");

    // ===================
    // TEST WRITING TO RF
    // ===================

    // test simple write
    addr1 = 5;
    wr_en = 1;
    wr_data = 1000;
    #10;
    if (rf.registers[addr1] != wr_data)
      $display("error: result not written to register when write enabled");

    // test not writing when write enable not high
    addr1 = 6;
    wr_en = 0;
    #10;
    if (rf.registers[addr1] == wr_data)
      $display("error: unexpected write to register when write not enabled");

    // try writing to PSR register 
    addr1 = PSR; 
    wr_data = 2**16 - 1;
    wr_en = 1;
    #10; 
    if (rf.registers[addr1] == wr_data)
      $display("error: writing to PSR register not blocked");

    // perform write so that there is data for further tests
    wr_en = 1;
    wr_data = 45;
    #10;
    wr_en = 0;

    // =========================
    // TEST READING FROM RF
    // =========================

    // test reading from 2 different registers
    addr1 = 5;
    addr2 = 6;
    #10;
    if (rd_data1 != rf.registers[addr1] || rd_data2 != rf.registers[addr2])
      $display("error: dual read did not function properly");

    // test reading from same register
    addr2 = addr1;
    #10;
    if (rd_data1 != rf.registers[addr1] || rd_data2 != rf.registers[addr1])
      $display("error: reading from same address did not function properly");

    // =======================
    // TEST TAKING IN NEW FLAGS
    // ======================= 

    // test that flags are not changed when write to flags not enabled
    C = 1;
    L = 1;
    F = 1;
    Z = 1;
    N = 1;
    f_en = 0;
    wr_en = 0;
    #10;
    if (rf.registers[PSR] != 0) 
      $display("error: flags were written to when f_en low");
    wr_en = 1;
    if (rf.registers[PSR] != 0) 
      $display("error: wr_en caused PSR to be written to (should only be written to on f_en)");

    // test that flags are updated when write to flags enabled
    f_en = 1;
    #10; 
    if (rf.registers[PSR] == 0) 
      $display("error: PSR not written to on f_en");

    $display("testbench complete");
  end

endmodule
