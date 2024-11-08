module tb_CPU(); 

  // period
  localparam T = 10;

  // time for one instruction to execute and write data to RF
  localparam TIME_INSTR = T * 2;
  // time for one instruction to execute and write data to RF from reset
  localparam TIME_INSTR_FROM_RESET = T * 3;

  // ----- Opcodes -----

  localparam RS_RD_OP         = 4'b0000;    // most Rsrc / Rdest based instructions (these all go by opcode extensions)
  localparam ANDI_OP          = 4'b0001;
  localparam ORI_OP           = 4'b0010;
  localparam XORI_OP          = 4'b0011;
  localparam LD_ST_J_OP       = 4'b0100;    // LOAD, STOR, Jcond, JAL
  localparam ADDI_OP          = 4'b0101;
  // localparam ADDUI_OP         = 4'b0110;    // (not implemented)
  // localparam ADDCI_OP         = 4'b0111;    // (not implemented)
  localparam SH_OP            = 4'b1000;    // shift instructions (this all go by opcode extensions)
  localparam SUBI_OP          = 4'b1001;
  // localparam SUBCI_OP         = 4'b1010;    // not implemented
  localparam CMPI_OP          = 4'b1011;
  localparam BCOND_OP         = 4'b1100;
  localparam MOVI_OP          = 4'b1101;
  localparam MULI_OP          = 4'b1110;
  localparam LUI_OP           = 4'b1111;

  // ----- Opcode extensions -----

  // Rsrc, Rdest extensions
  localparam AND_EXT          = 4'b0001;
  localparam OR_EXT           = 4'b0010;
  localparam XOR_EXT          = 4'b0011;
  localparam ADD_EXT          = 4'b0101;
  localparam ADDU_EXT         = 4'b0110;
  localparam ADDC_EXT         = 4'b0111;
  localparam SUB_EXT          = 4'b1001;
  localparam SUBC_EXT         = 4'b1010;
  localparam CMP_EXT          = 4'b1011;
  localparam MOV_EXT          = 4'b1101;
  localparam MUL_EXT          = 4'b1110;
  // shift extensions
  localparam LSHI_EXT         = 4'b0000;    // LSB is don't care condition
  localparam ASHUI_EXT        = 4'b0010;    // LSB is don't care condition
  localparam LSH_EXT          = 4'b0100;
  localparam ASHU_EXT         = 4'b0110;
  // load, store, jump extensions
  localparam LOAD_EXT         = 4'b0000; 
  localparam LPR_EXT          = 4'b0001;
  localparam SNXB_EXT         = 4'b0010;
  localparam STOR_EXT         = 4'b0100;
  localparam SPR_EXT          = 4'b0101;
  localparam ZRXB_EXT         = 4'b0110;
  localparam JAL_EXT          = 4'b1000;
  localparam TBIT_EXT         = 4'b1010;
  localparam JCOND_EXT        = 4'b1100;
  localparam SCOND_EXT        = 4'b1101;
  localparam TBITI_EXT        = 4'b1110;

  `define accessRF(addr) cpu.datapath.register_file.registers[addr]

  `define assertEqual(signal, value) \
          if (signal !== value ) begin \
            $display("ASSERT EQUAL FAILED"); \
            $display("got %d; expected %d", signal, value); \
          end \

  `define assertNotEqual(signal, value) \
          if (signal === value) begin \
            $display("ASSERT NOT EQUAL FAILED"); \
            $display("unexpected value: %d", signal); \
          end \

  `define loadRF(addr, value) cpu.datapath.register_file.registers[addr] = value;

  `define dispTestHeader(message) $display("---------------------\n%s\n--------------------", message);
          

  reg clk; 
  reg reset_n; 
  reg [15:0] mem_rd_data; 

  wire mem_wr_en; 
  wire [15:0] mem_addr; 
  wire [15:0] mem_wr_data; 

  integer result;

  CPU cpu (
    .clk(clk), 
    .reset_n(reset_n), 
    .mem_rd_data(mem_rd_data), 
    .mem_wr_en(mem_wr_en), 
    .mem_addr(mem_addr), 
    .mem_wr_data(mem_wr_data)
  );

  // reset CPU
  task DO_RESET; begin
    reset_n = 0; 
    #T; 
    reset_n = 1;
  end
  endtask

  task INSTR_ADD;
    input [3:0] Rsrc, Rdest;
    begin
      DO_RESET; // guarantees timing
      result = `accessRF(Rsrc) + `accessRF(Rdest);

      mem_rd_data = {RS_RD_OP, Rdest, ADD_EXT, Rsrc};
      #TIME_INSTR_FROM_RESET;
      `assertEqual(`accessRF(Rdest), result)
    end
  endtask

  task INSTR_SUBI; 
    input [3:0] Rdest; 
    input [7:0] imm; 
    begin 
      DO_RESET; 
      result = `accessRF(Rdest) - {{8{imm[7]}}, imm};

      mem_rd_data = {SUBI_OP, Rdest, imm}; 
      #TIME_INSTR_FROM_RESET; 
      `assertEqual(`accessRF(Rdest), result)
    end
  endtask

  task INSTR_ANDI; 
    input [3:0] Rdest;
    input [7:0] imm;
    begin 
      DO_RESET; 
      result = `accessRF(Rdest) & {8'b0 ,imm};

      mem_rd_data = {ANDI_OP, Rdest, imm};
      #TIME_INSTR_FROM_RESET; 
      `assertEqual(`accessRF(Rdest), result)
    end
  endtask

  task INSTR_MOV; 
    input [3:0] Rsrc, Rdest; 
    begin 
      DO_RESET; 

      mem_rd_data = {RS_RD_OP, Rdest, MOV_EXT, Rsrc};
      #TIME_INSTR_FROM_RESET; 
      `assertEqual(`accessRF(Rdest), `accessRF(Rsrc))
    end
  endtask

  task INSTR_MOVI; 
    input [3:0] Rdest; 
    input [7:0] imm; 
    begin 
      DO_RESET; 
      
      mem_rd_data = {MOVI_OP, Rdest, imm}; 
      #TIME_INSTR_FROM_RESET; 
      `assertEqual(`accessRF(Rdest), {8'b0, imm})
    end 
  endtask

  task INSTR_LSH; 
    input [3:0] Rsrc, Rdest;
    begin 
      DO_RESET; 
      if ($signed(`accessRF(Rsrc)) >= 0)
        result = `accessRF(Rdest) << `accessRF(Rsrc);
      else
        result = `accessRF(Rdest) >> -(`accessRF(Rsrc));

      mem_rd_data = {SH_OP, Rdest, LSH_EXT, Rsrc};
      #TIME_INSTR_FROM_RESET; 
      `assertEqual(`accessRF(Rdest), result)
    end 
  endtask
  
  task INSTR_LUI; 
    input [3:0] Rdest; 
    input [7:0] imm; 
    begin 
      DO_RESET; 
      result = imm << 8;

      mem_rd_data = {LUI_OP, Rdest, imm};
      #TIME_INSTR_FROM_RESET;
      `assertEqual(`accessRF(Rdest), result)
    end
  endtask

  task INSTR_LOAD; 
    input [3:0] Rdest, Raddr;
    input [15:0] data;
    begin 
      DO_RESET; 

      mem_rd_data = {LD_ST_J_OP, Rdest, LOAD_EXT, Raddr};
      #(T*2); // instruction fetched, controls set
      `assertEqual(mem_addr, `accessRF(Raddr))
      mem_rd_data = data;
      #T;     // new mem value latched
      `assertEqual(`accessRF(Rdest), data)
    end
  endtask

  task INSTR_STOR; 
    input [3:0] Rsrc, Raddr;
    reg [15:0] expected_addr;
    begin 
      DO_RESET;
      result = `accessRF(Rsrc); 
      expected_addr = `accessRF(Raddr);

      mem_rd_data = {LD_ST_J_OP, Rsrc, STOR_EXT, Raddr};
      #(T*2); 
      `assertEqual(mem_wr_data, result) 
      `assertEqual(mem_addr, expected_addr)
      `assertEqual(mem_wr_en, 1'b1)
    end
  endtask

  task INSTR_BCOND; 
    input [3:0] cond; 
    input [7:0] disp; 
    begin 
      DO_RESET;

      mem_rd_data = {BCOND_OP, cond, disp};
    end
  endtask 

  task INSTR_JCOND; 
    input [3:0] cond;
    input [3:0] Rtarget;
    begin 
      DO_RESET;

      mem_rd_data = {LD_ST_J_OP, cond, JAL_EXT, Rtarget};
    end
  endtask 

  task INSTR_JAL; 
    input [3:0] Rlink, Rtarget; 
    begin 
      DO_RESET;

      mem_rd_data = {LD_ST_J_OP, Rlink, JAL_EXT, Rtarget};

      // verify previous pc was saved 
      // verify fetching from new pc

    end
  endtask

  // generate clock
  initial begin 
    clk = 0; 
    forever #(T/2) clk = ~clk;
  end

  // initial values
  initial begin 
    mem_rd_data = 16'h0;
  end


  initial begin 
    $display("Starting testbench"); 
    $display("reseting CPU");
    DO_RESET;
    $display("reset complete");

    `dispTestHeader("ADD test")
    `loadRF(1, 5) 
    `loadRF(2, 90)
    INSTR_ADD(1, 2);

    `dispTestHeader("SUBI test") 
    `loadRF(15, -45)
    INSTR_SUBI(15, -78);

    `dispTestHeader("LSH test")
    `loadRF(8, 30) 
    `loadRF(2, 4) 
    $display("left shift");
    INSTR_LSH(2, 8);
    $display("right shift");
    `loadRF(3, 200) 
    `loadRF(9, -4)
    INSTR_LSH(9, 3);

    `dispTestHeader("LUI test")
    INSTR_LUI(8, 220);

    `dispTestHeader("ANDI test")
    `loadRF(6, 16'hF5F0)
    INSTR_ANDI(6, 8'h5F);

    `dispTestHeader("MOV test") 
    `loadRF(6, 78) 
    `loadRF(11, 400) 
    INSTR_MOV(11, 6);

    `dispTestHeader("MOVI test") 
    INSTR_MOVI(12, -40);

    `dispTestHeader("LOAD test") 
    `loadRF(3, 16'hF9F2)   // Raddr 
    INSTR_LOAD(0, 3, 16'hFFFF);

    `dispTestHeader("STOR test") 
    `loadRF(12, 16'h6789)   // Rsrc 
    `loadRF(13, 16'h3F8E)   // Raddr 
    INSTR_STOR(12, 13);

    $display("Testbench complete");
  end

endmodule
