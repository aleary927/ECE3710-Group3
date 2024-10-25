/*
* Testbench for verifying memory module.
*/
module tb_Memory();

  parameter SIZE = 1000;

  reg clk; 
  reg wr_en1, wr_en2; 
  reg [$clog2(SIZE) - 1:0] addr1, addr2;
  reg [15:0] wr_data1, wr_data2;

  wire [15:0] rd_data1, rd_data2;

  Memory #(.DATA_WIDTH(16), .SIZE(SIZE)) mem
            (.clk(clk), 
            .wr_en1(wr_en1), .wr_en2(wr_en2), 
            .addr1(addr1), .addr2(addr2), 
            .wr_data1(wr_data1), .wr_data2(wr_data2),
            .rd_data1(rd_data1), .rd_data2(rd_data2));

  // generate clk
  initial begin 
    clk = 0; 
    forever #5 clk = ~clk;
  end

  // initialize inputs
  initial begin 
    wr_en1 = 0; 
    wr_en2 = 0; 
    addr1 = 0; 
    addr2 = 0; 
    wr_data1 = 0; 
    wr_data2 = 0; 
  end

  // main testbench code
  integer i;
  initial begin 
    $display("Starting Memory testbench.");
    // ==================== 
    // SIMPLE TESTS 
    // ====================

    // test simple write 
    wr_en1 = 1;
    addr1 = 500; 
    wr_data1 = 999; 
    #10;
    if (mem.ram[addr1] != wr_data1) 
      $display("error: port 1 write doesn't work");

    wr_en1 = 0; 
    wr_en2 = 1;
    addr2 = 501; 
    wr_data2 = 5000; 
    #10; 
    if (mem.ram[addr2] != wr_data2) 
      $display("error: port 2 write doesn't work");
    wr_en2 = 0;

    // test simple read (read from address other port wrote to)
    addr1 = 501; 
    #10; 
    if (rd_data1 != 5000) 
      $display("error: port 1 read doesn't work");
    addr2 = 500; 
    #10;
    if (rd_data2 != 999) 
      $display("error: port 2 read doesn't work");


    // load first 100 memory locations with their own address for converience
    wr_en1 = 1;
    for (i = 0; i < 100; i = i + 1) begin 
      addr1 = i; 
      wr_data1 = i;
      #10;
    end
    wr_en1 = 0;

    // verify memory was written to 
    for (i = 0; i < 100; i = i + 1) begin 
      if (mem.ram[i] != i)
        $display("error: check first 100 mem addr init");
    end

    // ================= 
    // ADVANCED TESTS 
    // =================

    // test reading from both ports
    addr1 = 50; 
    addr2 = 60; 
    #10; 
    if (rd_data1 != 50 || rd_data2 != 60) 
      $display("error: simultaneous read of different addresses did not function correctly");

    // test reading from same port
    addr1 = 99;
    addr2 = 99; 
    #10; 
    if (rd_data1 != 99 || rd_data2 != 99)
      $display("error: simultaneous read of the same address did not function correctly");

    // test writing to both ports
    addr1 = 40; 
    addr2 = 41; 
    wr_data1 = 70; 
    wr_data2 = 65;
    wr_en1 = 1; 
    wr_en2 = 1;
    #10; 
    if (mem.ram[addr1] != 70 || mem.ram[addr2] != 65)
      $display("error: simultaneous write to two different addresses did not function correctly");
    wr_en1 = 0; 
    wr_en2 = 0;

    // test writing to same port?
    
    // check data that comes back when doing write
    addr1 = 200; 
    addr2 = 201; 
    wr_data1 = 3000; 
    wr_data2 = 3001;
    wr_en1 = 1; 
    wr_en2 = 1; 
    #10; 
    if (rd_data1 != 3000 || rd_data2 != 3001) 
      $display("error: write data did not come back as read data when performing write");
    wr_en1 = 0; 
    wr_en2 = 0;

    // check read data when performing a write and read on same address
    // should get new data back on write port, old data back on read port
    addr2 = 200; 
    wr_en1 = 1; 
    wr_data1 = 23; 
    #10; 
    if (rd_data1 != 23 || rd_data2 != 3000)
      $display("error: unexpected read result when performing write and read on same address");
    wr_en1 = 0;


    // =================== 
    // SYNCRONOUS TESTS
    // ==================

    // read from addrs 0 and 1   
    addr1 = 0; 
    addr2 = 1; 
    #10;        

    // check for syncronous read 
    addr1 = 5;
    addr2 = 6;
    #1;         // advance partial clock cycle
    if (rd_data1 == 5 || rd_data2 == 6) 
      $display("error: read not performed syncronously on at least one port");
    #9; // advance to next clock cycle
    // already verifyied by previous tests, but check to be sure
    if (rd_data1 != 5 || rd_data2 != 6) 
      $display("error: read did not function during syncronous test");

    // check for syncrounous write
    addr1 = 8; 
    addr2 = 9;
    wr_data1 = 100; 
    wr_data2 = 200;
    wr_en1 = 1; 
    wr_en2 = 1;
    #1;             // advane partial clock cycle
    if (mem.ram[addr1] == 100 || mem.ram[addr2] == 200) 
      $display("error: write not performed syncronously on at least on port");
    #9;       // advance to next clock cycle 
    // already verifyed, but check for certainty
    if (mem.ram[addr1] != 100 || mem.ram[addr2] != 200) 
      $display("error: write did not function during syncronous test");
    wr_en1 = 0; 
    wr_en2 = 0;
    

    $display("testbench complete");
  end

endmodule
