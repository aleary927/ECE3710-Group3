/*
* Testbench for verifiying the DataPath module.
*/
module tb_DataPath(); 
  
  reg clk; 
  reg reset_n;
  
  reg wr_en;        // reg file write en
  reg [3:0] alu_sel;      // alu function
  reg alu_src;      // alu source
  reg next_instr;       // use PC as addr
  reg [1:0] wr_bk_sel;    // data to write back to reg file
  reg cmp_f_en, of_f_en, z_f_en;    // flag enables
  reg pc_en, instr_en;      // wr_en for pc, instr regs
  reg [15:0] mem_rd_data;      // data to memory
  reg [1:0] pc_addr_mode;     // mode to use to calc next PC
  reg [1:0] sign_ext_mode;
  
  wire [15:0] mem_wr_data;     // data to memory
  wire [15:0] mem_addr;       // addr to memory
  wire [3:0] opcode, opcode_ext;  // opcode for controller
  wire cmp_result;

  integer res; // for testing 

  // ALU function codes
  localparam ADD = 4'b0000; 
  localparam SUB = 4'b0001; 
  localparam AND = 4'b0010; 
  localparam OR  = 4'b0011; 
  localparam XOR = 4'b0100; 
  localparam NOT = 4'b0101;
  localparam LSH = 4'b0110; 
  localparam ASH = 4'b0111;
  localparam MUL = 4'b1000;

  // PC ALU function codes
  localparam NEXT_INSTR = 2'b00; 
  localparam OFFSET     = 2'b01; 
  localparam ABSOLUTE   = 2'b10;
  
  // index's of flag bits in PSR register
  localparam C_IND = 0;
  localparam L_IND = 2;
  localparam F_IND = 5;
  localparam Z_IND = 6;
  localparam N_IND = 7;

  DataPath datapath(
    .clk(clk), 
    .reset_n(reset_n), 
    .wr_en(wr_en), 
    .alu_sel(alu_sel), 
    .alu_src(alu_src), 
    .write_back_sel(wr_bk_sel),
    .pc_en(pc_en), 
    .next_instr(next_instr),
    .instr_en(instr_en), 
    .pc_addr_mode(pc_addr_mode),
    .sign_ext_mode(sign_ext_mode),
    .cmp_f_en(cmp_f_en), 
    .of_f_en(of_f_en), 
    .z_f_en(z_f_en),
    .mem_rd_data(mem_rd_data), 
    .mem_wr_data(mem_wr_data), 
    .mem_addr(mem_addr),
    .opcode(opcode), 
    .opcode_ext(opcode_ext),
    .cmp_result(cmp_result)
  );

  // generate clock 
  initial begin 
    clk = 0; 
    forever #5 clk = ~clk;
  end

  // initial conditions
  initial begin 
    wr_en = 0; 
    alu_sel = 0; 
    alu_src = 0; 
    wr_bk_sel = 0; 
    cmp_f_en = 0; 
    of_f_en = 0; 
    z_f_en = 0; 
    pc_en = 0; 
    next_instr = 0;
    instr_en = 0;
    mem_rd_data = 0;
    pc_addr_mode = 0;
    reset_n = 0;
    sign_ext_mode = 0;
  end

  initial begin
    $display("Starting DataPath testbench");
    #10; 
    reset_n = 1;  

    // ==========================
    // INSTRUCTION REGISTER TESTS 
    // ==========================

    // test reading new instruction 
    instr_en = 1; 
    mem_rd_data = 16'hFEDC;
    #10; 
    if (datapath.current_instr != mem_rd_data)
      $display("error: instruction reg did not read new value");
    if (datapath.Rdest != 4'hE || datapath.Rsrc != 4'hC)
      $display("error: did not extract Rsrc and Rdest from instruction reg properly");
    if (opcode != 4'hF | opcode_ext != 4'hD) 
      $display("error: did not extract opcode and opcode_ext from instruction reg properly");

    // test sign extension
    mem_rd_data = 16'h00F0;  // load negative 
    #10; 
    if (datapath.immediate_ext != 16'hFFF0)
      $display("error: sign extension for immediate did not work");
    mem_rd_data = 16'h0055; // load positive 
    #10; 
    if (datapath.immediate_ext != 16'h0055) 
      $display("error: should be no sign extension for immediate on positive value");
    instr_en = 0;

    // test not reading new instruction 
    mem_rd_data = 16'hF5F5;
    #10; 
    if (datapath.current_instr == mem_rd_data)
      $display("error: instruction reg was written to when enable signal low");

    // ========================
    // REGISTER FILE TESTS 
    // ======================== 

    // test storing data from memory in reg file
    instr_en = 1; 
    mem_rd_data = 16'h0800; #10; // store in register 8, addr is reg 0
    datapath.register_file.registers[0] = 16'h4444;   // to check address
    instr_en = 0;
    mem_rd_data = 16'hFFFF; 
    wr_bk_sel = 2'b1;  
    wr_en = 1;
    #10; 
    if (datapath.register_file.registers[8] != mem_rd_data) 
      $display("error: could not write from memory to register file");
    if (mem_addr != datapath.register_file.registers[0]) // check address
      $display("error: didn't use correct memory address for write from memory to reg file");
    wr_en = 0;

    // test moving data from one register to another
    instr_en = 1; 
    mem_rd_data = 16'h0E08; #10;  // Rdest = E, Rsrc = 8
    instr_en = 0; 
    wr_bk_sel = 2'b10;
    wr_en = 1;
    #10;  // need another clock cycle to write to reg file
    if (datapath.register_file.registers[4'hE] != datapath.register_file.registers[8]) 
      $display("error: could not move data from one reg to another");
    wr_en = 0;
    
    // test writing data from reg file to memory
    datapath.register_file.registers[0] = 16'h166F; // load more data 
    // store data from reg 0 to addr from reg 8
    datapath.instr_reg.q = 16'h0008;
    #10;
    if (mem_wr_data != datapath.register_file.registers[0])
      $display("error: didn't get correct data for memory store");
    if (mem_addr != datapath.register_file.registers[8]) // check address
      $display("error: didn't get correct address for memory store");

    // test loading immediate value 
    wr_en = 1;
    wr_bk_sel = 2'b11;  // select immediate for write 
    datapath.instr_reg.q = 16'h0AF9;    // write 0xFFF9 to Rdest A
    #10; 
    if (datapath.register_file.registers[16'hA] != 16'hFFF9)
      $display("error: didn't write immediate to reg file correctly");
    wr_en = 0;

    // ========================== 
    // ALU OPERATION TESTS 
    // ==========================

    // test selecting different alu function  
    // select ADD and SUB and check results,
    // no need to check other functions, just verify 
    // that selecting a function works
    alu_sel = ADD;
    datapath.instr_reg.q = 16'h0203;  // Rdest = 2, Rsrc = 3
    datapath.register_file.registers[2] = 16'd65;
    datapath.register_file.registers[3] = 16'd55;
    res = 65 + 55;
    #10;
    if (datapath.alu_result != res)
      $display("error: didn't compute correct result when ADD selected");
    alu_sel = SUB;
    res = 65 - 55;
    #10; 
    if (datapath.alu_result != res) begin
      $display("result: %d", datapath.alu_result);
      $display("error: didn't compute correct result when SUB selected");
    end

    // test alu op between 2 regs and writing back to reg file
    // using previous result (Rdest is 2)
    wr_bk_sel = 2'b00;
    alu_src = 0;
    wr_en = 1;
    #10; 
    if (datapath.register_file.registers[2] != res) 
      $display("error: writing alu result back to register file failed");

    // test alu op between reg and imm, and writing back to reg file
    alu_sel = ADD;
    alu_src = 1;
    datapath.instr_reg.q = 16'h0708;  // Rdest = 7, imm = 8
    datapath.register_file.registers[7] = 16'd1000;
    res = 1000 + 8;
    #10;
    if (datapath.register_file.registers[7] != res) 
      $display("error: writing result of immediate alu operation failed");
    wr_en = 0;
    
    // test updating psr flags (if one works they all should, so just test Z)
    datapath.instr_reg.q = 16'h0304;
    alu_sel = SUB;
    datapath.register_file.registers[3] = 16'd60;
    datapath.register_file.registers[4] = 16'd60;
    alu_src = 0;
    z_f_en = 1;
    #10; 
    if (datapath.psr[Z_IND] != 1) 
      $display("error: updating flag in PSR failed");
    z_f_en = 0;

    // ============= 
    // PC TESTS 
    // =============

    // test incrementing PC
    datapath.pc.q = 16'b0;
    pc_addr_mode = NEXT_INSTR;
    pc_en = 1;
    #10; 
    if (datapath.pc_current != 16'b1) 
      $display("error: PC did not increment in NEXT_INSTR mode");

    // test adding offset to PC
    // test positive, then negative offset
    pc_addr_mode = OFFSET;
    datapath.instr_reg.q = 16'h0008;    // immediate is 8
    #10; 
    if(datapath.pc_current != 16'd9)  // should be 9 (was 1, added 8)
      $display("error: positive offset PC arithmetic failure");
    datapath.instr_reg.q = 16'h00FD;    // immediate is  -3
    #10; 
    if(datapath.pc_current != 16'd6) // should be 6 (was 9, subtracted 3) begin
      $display("error: negative offset PC arithmetic failure");

    // test jumping to absolute address
    pc_addr_mode = ABSOLUTE;
    datapath.instr_reg.q = 16'h000C;  // jump to value in reg C
    datapath.register_file.registers[4'hC] = 16'hF67D;  // load address to Rtarget
    #10; 
    if (datapath.pc_current != 16'hF67D) 
      $display("error: jumping to absolute address in reg file failed");
    
    // test not writing to PC
    pc_en = 0;
    datapath.instr_reg.q = 16'h0001;
    datapath.register_file.registers[1] = 16'd2000;
    datapath.pc.q = 16'b0;
    #10;
    if (datapath.pc_current == 16'd2000)
      $display("error: PC updated when not enabled");

    // test using PC as memory address 
    next_instr = 1;
    datapath.pc.q = 16'hFFF;
    #10;
    if (mem_addr != 16'hFFF) 
      $display("error: using PC as memory address failed");
    next_instr = 0;

    // test reseting PC 
    // note that the other registers will reset but only the PC matters, 
    // as it determines where to get the first instruction from, and
    // all other registers will be overwritten by normal operation
    reset_n = 0;
    #10;
    if (datapath.pc_current != 16'b0) 
      $display("error: PC did not result correctly");
    reset_n = 1;

    $display("testbench complete.");
  end

endmodule
