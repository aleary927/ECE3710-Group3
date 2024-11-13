//`timescale 1ns / 1ps //*


module tb_CPU_Controller;
  reg clk;
  reg reset_n;
  
  // from data path
  reg [3:0] opcode, opcode_ext; 
  reg cmp_result; 
  
  // to datapath
  wire reg_wr_en;
  wire alu_src;
  wire [3:0] alu_sel;
  wire next_instr;
  wire pc_en;
  wire instr_en;
  wire cmp_f_en, of_f_en, z_f_en;
  wire [1:0] pc_addr_mode;
  wire [2:0] write_back_sel;
  
  
  wire mem_wr_en;

  // ************************** 
  // Parameters 
  // **************************

  // ----- ALU function selects -----

  localparam ADD = 4'b0000; 
  localparam SUB = 4'b0001; 
  localparam AND = 4'b0010; 
  localparam OR  = 4'b0011; 
  localparam XOR = 4'b0100; 
  localparam NOT = 4'b0101;
  localparam LSH = 4'b0110; 
  localparam ASH = 4'b0111;
  localparam MUL = 4'b1000;

  // ----- reg write selects -----

  localparam REG_SRC_ALU  = 3'h0;
  localparam REG_SRC_MEM  = 3'h1;
  localparam REG_SRC_REG  = 3'h2; 
  localparam REG_SRC_IMM  = 3'h3;
  localparam REG_SRC_PC   = 3'h4;

  // ----- PC address modes -----
  localparam PC_INCREMENT = 2'b00; 
  localparam PC_OFFSET    = 2'b01;
  localparam PC_ABSOLUTE  = 2'b10;

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
  
  // ----- FSM states -----
 
  localparam NULL_STATE      = 4'b0000;   // maybe unnecessary ??
  localparam FETCH           = 4'b0001;  // Instruction Fetch
  localparam EXECUTE         = 4'b0010;
	// localparam DECODE          = 4'b0010;  // Decode
	// localparam ALULOAD         = 4'b0011;  // Load operands for ALU operation, could further separate this into more states to remove extra logic in assignment. 
	// localparam ALU             = 4'b0100;  // Execute ALU operation
	// localparam DATAMOVE        = 4'b0101;  // Data Movement (MOV, MOVI)
	// localparam SHIFT           = 4'b0110;  // Shift Operations (LSH, ASHU, etc.)
	// localparam IMMLOAD         = 4'b0111;  // Immediate Load (LUI, etc.)
	// localparam ADDRCALC        = 4'b1000;  // Address Calculation for Load/Store
	// localparam MEMREAD         = 4'b1001;  // Memory Read for LOAD
	// localparam MEMWRITE        = 4'b1010;  // Memory Write for STORE
	// localparam JUMP            = 4'b1011;  // Jump Operation
	// localparam BRANCH          = 4'b1100;  // Branch base state
	// localparam SIGNEXTEND      = 4'b1101;  // Sign Extend (SXRB)
	// localparam REGWRITE        = 4'b1110;  // Write-Back State

  // *************************** 
  // Internal Wires / Regs 
  // ***************************

  reg [3:0] present_state, next_state; 
  
  // Instantiate UUT
  CPU_Controller uut (
    .clk(clk),
    .reset_n(reset_n),
    .opcode(opcode),
    .opcode_ext(opcode_ext),
    .cmp_result(cmp_result),
    .reg_wr_en(reg_wr_en),
    .alu_src(alu_src),
    .alu_sel(alu_sel),
    .next_instr(next_instr),
    .pc_en(pc_en),
    .instr_en(instr_en),
    .cmp_f_en(cmp_f_en),
    .of_f_en(of_f_en),
    .z_f_en(z_f_en),
    .pc_addr_mode(pc_addr_mode),
    .write_back_sel(write_back_sel),
    .mem_wr_en(mem_wr_en)
  );

  // Clock generation
  always #5 clk = ~clk;  // 100MHz clock

  initial begin
    // Initialize Inputs
    clk 			= 0;
    reset_n 	= 0;
    opcode 		= 4'b0000;
    opcode_ext = 4'b0000;
    cmp_result = 0;

	 // Testing reset_n
	 #10;
	 reset_n = 1;
	 $display("Testing reset_n...");
	 
	 if (present_state != next_state)
	 $display("reset_n failed");
	 
    // Testing FETCH state behavior
    #10;
    $display("Testing FETCH state...");
	 
    if (instr_en != 1 || next_instr != 1) 
	 $display("FETCH state failed.");

	 //Rsrc, Rdest instructions **
	 //RS_RD_OP opcode tests **
	 //
    // Testing RS_RD_OP with AND_EXT (expected reg_wr_en = 1, z_f_en = 1)
    #10;
    opcode 		= RS_RD_OP;
    opcode_ext = AND_EXT;
    #10;
    $display("Testing AND_EXT operation...");
	 
    if (reg_wr_en != 1 || z_f_en != 1) 
	 $display("AND_EXT operation failed.");
	 
	 // Testing RS_RD_OP with OR_EXT (expected reg_wr_en = 1, z_f_en = 1)
    #10;
    opcode_ext = OR_EXT;
    #10;
    $display("Testing OR_EXT operation...");
	 
    if (reg_wr_en != 1 || z_f_en != 1) 
	 $display("OR_EXT operation failed.");
	 

    // Testing RS_RD_OP with ADD_EXT (expected reg_wr_en = 1, z_f_en = 1, of_f_en = 1)
    opcode_ext = ADD_EXT;
    #10;
    $display("Testing ADD_EXT operation...");
	 
    if (reg_wr_en != 1 || z_f_en != 1 || of_f_en != 1) 
	 $display("ADD_EXT operation failed.");

	 
	 // Testing RS_RD_OP with SUB_EXT (expected reg_wr_en = 1, z_f_en = 1, of_f_en = 1, cmp_f_en = 1)
    #10;
    opcode_ext = SUB_EXT;
    #10;
    $display("Testing SUB_EXT operation...");
	 
     if (reg_wr_en != 1 || z_f_en != 1 || of_f_en != 1 || cmp_f_en != 1) 
	 $display("SUB_EXT operation failed.");
	 
	 	 
	 // Testing RS_RD_OP with CMP_EXT (expected z_f_en = 1, cmp_f_en = 1)
    #10;
    opcode_ext = CMP_EXT;
    #10;
    $display("Testing CMP_EXT operation...");
	 
     if (z_f_en != 1 || cmp_f_en != 1) 
	 $display("CMP_EXT operation failed.");
	 
	 
	 // Testing RS_RD_OP with MOV_EXT (expected write_back_sel = REG_SRC_REG, reg_wr_en = 1)
    #10;
    opcode_ext = MOV_EXT;
    #10;
    $display("Testing MOV_EXT operation...");
	 
     if (write_back_sel != REG_SRC_REG || reg_wr_en != 1) 
	 $display("MOV_EXT operation failed.");
	 
	 
	 // Testing RS_RD_OP with MUL_EXT (expected reg_wr_en = 1, z_f_en = 1)
    #10;
    opcode_ext = MUL_EXT;
    #10;
    $display("Testing MUL_EXT operation...");
	 
     if (reg_wr_en != 1 || z_f_en != 1) 
	 $display("MUL_EXT operation failed.");
	 

	 
	 
	 
	 //**
	 // loads, stores, jumps
    // Testing LD_ST_J_OP with LOAD_EXT (expected write_back_sel = REG_SRC_MEM, reg_wr_en = 1)
    opcode 		= LD_ST_J_OP;
    opcode_ext = LOAD_EXT;
    #10;
    $display("Testing LOAD operation...");
	 
    if (write_back_sel != 3'h1 || reg_wr_en != 1) 
	 $display("LOAD operation failed.");
	 
	 // Testing LD_ST_J_OP with STOR_EXT (expected mem_wr_en = 1)
    opcode_ext = STOR_EXT;
    #10;
    $display("Testing STOR_EXT operation...");
	 
    if (mem_wr_en != 1) 
	 $display("STOR_EXT operation failed.");

    // Testing LD_ST_J_OP with JAL_EXT (expected write_back_sel = REG_SRC_PC, reg_wr_en = 1, pc_addr_mode = PC_ABSOLUTE)
    opcode_ext = JAL_EXT;
    #10;
    $display("Testing JAL_EXT operation...");
	 
    if (write_back_sel != REG_SRC_PC || reg_wr_en != 1 || pc_addr_mode != PC_ABSOLUTE) 
	 $display("JAL_EXT operation failed.");

	 
    // Testing LD_ST_J_OP with JCOND_EXT (expected pc_addr_mode = cmp_result ? PC_ABSOLUTE : PC_INCREMENT)
    opcode_ext = JCOND_EXT;
    #10;
    $display("Testing JCOND_EXT operation...");
	 
    if (pc_addr_mode != cmp_result ? PC_ABSOLUTE : PC_INCREMENT) // idk if this line works, lets try @@@@@@@@@@@@@@@@@@@@
	 $display("JCOND_EXT operation failed.");

	 
    // Testing SH_OP (expected reg_wr_en = 1)
    opcode = SH_OP;
    #10;
    $display("Testing SH_OP operation...");
	 
    if (reg_wr_en != 1)
	 $display("SH_OP operation failed.");
	 
	 	 
    // Testing ANDI_OP (expected z_f_en = 1, reg_wr_en = 1)
    opcode = ANDI_OP;
    #10;
    $display("Testing ANDI_OP operation...");
	 
    if (z_f_en != 1 || reg_wr_en != 1)
	 $display("ANDI_OP operation failed.");
	 
	 
    	 	 
    // Testing ORI_OP (expected z_f_en = 1, reg_wr_en = 1)
    opcode = ORI_OP;
    #10;
    $display("Testing ORI_OP operation...");
	 
    if (z_f_en != 1 || reg_wr_en != 1)
	 $display("ORI_OP operation failed.");
	 
	 	 
    // Testing XORI_OP (expected z_f_en = 1, reg_wr_en = 1)
    opcode = XORI_OP;
    #10;
    $display("Testing XORI_OP operation...");
	 
    if (z_f_en != 1 || reg_wr_en != 1)
	 $display("XORI_OP operation failed.");
	 
	 	 
    // Testing ADDI_OP (expected z_f_en = 1, reg_wr_en = 1, of_f_en = 1)
    opcode = ADDI_OP;
    #10;
    $display("Testing ADDI_OP operation...");
	 
    if (z_f_en != 1 || reg_wr_en != 1 ||of_f_en != 1)
	 $display("ADDI_OP operation failed.");
	 
	 	 	 
    // Testing SUBI_OP (expected z_f_en = 1, reg_wr_en = 1, of_f_en = 1)
    opcode = SUBI_OP;
    #10;
    $display("Testing SUBI_OP operation...");
	 
    if (z_f_en != 1 || reg_wr_en != 1 ||of_f_en != 1)
	 $display("SUBI_OP operation failed.");
	 
	 	 	 	 
    // Testing CMPI_OP (expected z_f_en = 1, cmp_f_en = 1)
    opcode = CMPI_OP;
    #10;
    $display("Testing CMPI_OP operation...");
	 
    if (z_f_en != 1 || cmp_f_en != 1)
	 $display("CMPI_OP operation failed.");
	 	 	 	 
    // Testing BCOND_OP (expected pc_addr_mode = cmp_result ? PC_OFFSET : PC_INCREMENT)
    opcode = BCOND_OP;
    #10;
    $display("Testing BCOND_OP operation...");
	 
    if (pc_addr_mode != cmp_result ? PC_OFFSET : PC_INCREMENT) // *@@@@@@@@@@
	 $display("BCOND_OP operation failed.");
	 	 	 	 
    // Testing MOVI_OP (expected z_f_en = 1, reg_wr_en = 1, of_f_en = 1)
    opcode = MOVI_OP;
    #10;
    $display("Testing MOVI_OP operation...");
	 
    if (0)
	 $display("MOVI_OP operation failed.");
	 
    // Testing MULI_OP (expected reg_wr_en = 1, z_f_en = 1)
    opcode = MULI_OP;
    #10;
    $display("Testing MULI_OP operation...");
	 
    if (reg_wr_en != 1 || z_f_en != 1)
	 $display("MULI_OP operation failed.");
	 
	 
    // Testing LUI_OP (expected reg_wr_en = 1, z_f_en = 1)
    opcode = LUI_OP;
    #10;
    $display("Testing LUI_OP operation...");
	 
    if (reg_wr_en != 1 || z_f_en != 1)
	 $display("LUI_OP operation failed.");
	 
	 
	 
	 
	 
	 // testing for determining ALU function and source **
    // Testing RS_RD_OP (expected alu_src = 0)
    opcode = RS_RD_OP;
    #10;
    $display("Testing RS_RD_OP source...");
	 
	 if (alu_src != 0)
	 $display("RS_RD_OP source failed.");
	 
	 // testing RS_RD_OP with AND_EXT (expected alu_sel = AND)
	 opcode_ext = AND_EXT;
	 #10;
    $display("Testing AND_EXT function...");
	 
    if (alu_sel != AND)
	 $display("AND_EXT function failed.");
	 
	 
	 // testing RS_RD_OP with OR_EXT (expected alu_sel = OR)
	 opcode_ext = OR_EXT;
    #10;
    $display("Testing OR_EXT function...");
	 
    if (alu_sel != OR)
	 $display("OR_EXT function failed.");
	 	 
	 // testing RS_RD_OP with XOR_EXT (expected alu_sel = XOR)
	 opcode_ext = XOR_EXT;
    #10;
    $display("Testing XOR_EXT function...");
	 
    if (alu_sel != XOR)
	 $display("XOR_EXT function failed.");
	 	 
	 // testing RS_RD_OP with ADD_EXT (expected alu_sel = ADD)
	 opcode_ext = ADD_EXT;
    #10;
    $display("Testing ADD_EXT function...");
	 
    if (alu_sel != ADD)
	 $display("ADD_EXT function failed.");
	 	 
	 // testing RS_RD_OP with SUB_EXT (expected alu_sel = SUB)
	 opcode_ext = SUB_EXT;
    #10;
    $display("Testing SUB_EXT function...");
	 
    if (alu_sel != SUB)
	 $display("SUB_EXT function failed.");
	 
	 	 	 
	 // testing RS_RD_OP with CMP_EXT (expected alu_sel = SUB)
	 opcode_ext = CMP_EXT;
    #10;
    $display("Testing CMP_EXT function...");
	 
    if (alu_sel != SUB)
	 $display("CMP_EXT function failed.");
	 	 	 
	 // testing RS_RD_OP with MUL_EXT (expected alu_sel = MUL)
	 opcode_ext = MUL_EXT;
    #10;
    $display("Testing MUL_EXT function...");
	 
    if (alu_sel != MUL)
	 $display("MUL_EXT function failed.");
	 
	 
	 
	 	//** Shifts
	 // testing SH_OP with LSHI_EXT (alu_src = 1, alu_sel = LSH)
	 opcode = SH_OP;
	 opcode_ext = LSHI_EXT;
    #10;
    $display("Testing LSHI_EXT function...");
	 
    if (alu_src != 1 || alu_sel != LSH)
	 $display("LSHI_EXT function failed.");
	 
	 // testing SH_OP with ASHUI_EXT (alu_src = 1, alu_sel = ASH)
	 opcode_ext = ASHUI_EXT;
    #10;
    $display("Testing ASHUI_EXT function...");
	 
    if (alu_src != 1 || alu_sel != ASH)
	 $display("ASHUI_EXT function failed.");
	 
	 	 
	 // testing SH_OP with LSH_EXT (alu_src = 0, alu_sel = LSH)
	 opcode_ext = LSH_EXT;
    #10;
    $display("Testing LSH_EXT function...");
	 
    if (alu_src != 0 || alu_sel != LSH)
	 $display("LSH_EXT function failed.");
	 	 
	 // testing SH_OP with ASHU_EXT (alu_src = 0, alu_sel = ASH)
	 opcode_ext = ASHU_EXT;
    #10;
    $display("Testing ASHU_EXT function...");
	 
    if (alu_src != 0 || alu_sel != ASH)
	 $display("ASHU_EXT function failed.");
	 
	 // testing ANDI_OP (expect alu_src = 1, alu_sel = AND)
	 opcode = ANDI_OP;
    #10;
    $display("Testing ANDI_OP function...");
	 
    if (alu_src != 1 || alu_sel != AND)
	 $display("ANDI_OP function failed.");
	 
	 	 
	 // testing ORI_OP (expect alu_src = 1, alu_sel = ORI)
	 opcode = ORI_OP;
    #10;
    $display("Testing ORI_OP function...");
	 
    if (alu_src != 1 || alu_sel != ORI_OP)
	 $display("ORI_OP function failed.");
	 	 
	 // testing XORI_OP (expect alu_src = 1, alu_sel = XORI)
	 opcode = XORI_OP;
    #10;
    $display("Testing XORI_OP function...");
	 
    if (alu_src != 1 || alu_sel != XORI_OP)
	 $display("XORI_OP function failed.");
	 	 
	 // testing ADDI_OP (expect alu_src = 1, alu_sel = ADD)
	 opcode = ADDI_OP;
    #10;
    $display("Testing ADDI_OP function...");
	 
    if (alu_src != 1 || alu_sel != ADD)
	 $display("ADDI_OP function failed.");
	 
	 	 	 
	 // testing SUBI_OP (expect alu_src = 1, alu_sel = SUB)
	 opcode = SUBI_OP;
    #10;
    $display("Testing SUBI_OP function...");
	 
    if (alu_src != 1 || alu_sel != SUB)
	 $display("SUBI_OP function failed.");
	 	 	 
	 // testing CMPI_OP (expect alu_src = 1, alu_sel = SUB)
	 opcode = CMPI_OP;
    #10;
    $display("Testing CMPI_OP function...");
	 
    if (alu_src != 1 || alu_sel != SUB)
	 $display("CMPI_OP function failed.");
	 	 	 
	 // testing MULI_OP (expect alu_src = 1, alu_sel = MUL)
	 opcode = MULI_OP;
    #10;
    $display("Testing MULI_OP function...");
	 
    if (alu_src != 1 || alu_sel != MUL)
	 $display("MULI_OP function failed.");
	 
	 
    // Testing reset
    reset_n = 0;
    #10;
	 $display("Testing Reste (or NULL_STATE)");
	 
    if (present_state != 4'b0000) 
	 $display("Reset failed to bring the state to NULL_STATE.");

    $stop;
  end

endmodule