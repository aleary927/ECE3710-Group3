/*
* Testbench for verifying RF (register file) module.
*/

module tb_RF();

  reg clk;

  reg [2:0] addr1, addr2; // addresses
  reg wr_en;           // write enable
  reg [15:0] wr_data;    // write data
  wire [15:0] rd_data1, rd_data2; // read data

  RF rf(.clk(clk), .wr_en(wr_en), .wr_data(wr_data), .addr1(addr1), .addr2(addr2), .rd_data1(rd_data1), .rd_data2(rd_data2));

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
    if (rf.RAM[addr1] != wr_data)
      $display("error: result not written to register when write enabled");

    // test not writing when write enable not high
    addr1 = 6;
    wr_en = 0;
    #10;
    if (rf.RAM[addr1] == wr_data)
      $display("error: unexpected write to register when write not enabled");


    // perform write
    wr_en = 1;
    #10;
    wr_en = 0;

    // =========================
    // TEST READING FROM RF
    // =========================

    // test reading from 2 different registers
    addr1 = 5;
    addr2 = 6;
    #10;
    if (rd_data1 != rf.RAM[addr1] || rd_data2 != rf.RAM[addr2])
      $display("error: dual read did not function properly");

    // test reading from same register
    addr2 = addr1;
    #10;
    if (rd_data1 != rf.RAM[addr1] || rd_data2 != rf.RAM[addr1])
      $display("error: reading from same address did not function properly");

    // =======================
    // TEST TAKING IN NEW FLAGS
    // ======================= TODO

    // test that flags are not changed when write to flags not enabled

    // test changing flags when alu op performed

    // test changing flags when comparision op performed

    $display("testbench complete");
  end

endmodule
