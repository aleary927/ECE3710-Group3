/*
* Control FSM for CR16 CPU.
*/
module CPU_Controller(
  input clk, 
  input reset_n, 

  // from data path
  input [3:0] opcode, opcode_ext, 
  input cmp_result,

  // to datapath 
  output reg_wr_en, 
  output alu_src, 
  output [3:0] alu_sel, 
  output next_instr,
  output pc_en, 
  output instr_en, 
  output cmp_f_en, of_f_en, z_f_en, 
  output [1:0] pc_addr_mode, 
  output [1:0] write_back_sel, 

  // to memory
  output mem_wr_en 
); 

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
  localparam SPR_EXT          - 4'b0101;
  localparam ZRXB_EXT         = 4'b0110;
  localparam JAL_EXT          = 4'b1000;
  localparam TBIT_EXT         = 4'b1010;
  localparam JCOND_EXT        = 4'b1100;
  localparam SCOND_EXT        = 4'b1101;
  localparam TBITI_EXT        = 4'b1110;
  
  // ----- FSM states -----
 
  localparam FETCH           = 4'b0001;  // Instruction Fetch
	localparam DECODE          = 4'b0010;  // Decode
	localparam ALULOAD         = 4'b0011;  // Load operands for ALU operation, could further separate this into more states to remove extra logic in assignment. 
	localparam ALU             = 4'b0100;  // Execute ALU operation
	localparam DATAMOVE        = 4'b0101;  // Data Movement (MOV, MOVI)
	localparam SHIFT           = 4'b0110;  // Shift Operations (LSH, ASHU, etc.)
	localparam IMMLOAD         = 4'b0111;  // Immediate Load (LUI, etc.)
	localparam ADDRCALC        = 4'b1000;  // Address Calculation for Load/Store
	localparam MEMREAD         = 4'b1001;  // Memory Read for LOAD
	localparam MEMWRITE        = 4'b1010;  // Memory Write for STORE
	localparam JUMP            = 4'b1011;  // Jump Operation
	localparam BRANCH          = 4'b1100;  // Branch base state
	localparam SIGNEXTEND      = 4'b1101;  // Sign Extend (SXRB)
	localparam REGWRITE        = 4'b1110;  // Write-Back State

  // *************************** 
  // Internal Wires / Regs 
  // ***************************

  reg [3:0] preset_state, next_state; 
  
  // ************************** 
  // FSM 
  // **************************
  
  // state transition
  always @(posedge clk) begin 

    if (!reset_n) 
      present_state <= FETCH; 
    else 
      present_state <= next_state;
  end

  // Generate next state
	always @(*) begin 
		 case (present_state)
			  FETCH: 
					next_state = DECODE;
	
			  DECODE: 
			
				 case (opcode)
					  RS_RD_OP: begin
							case (opcode_ext)
								 ADD_EXT:  next_state = ALULOAD; // ADD
								 // ADDU_EXT:  next_state = ALULOAD; // ADDU (not implemented)
								 // ADDC_EXT:  next_state = ALULOAD; // ADDC (not implemented)
								 SUB_EXT:  next_state = ALULOAD; // SUB
								 SUBC_EXT:  next_state = ALULOAD; // SUBC
								 CMP_EXT:  next_state = ALULOAD; // CMP
								 AND_EXT:  next_state = ALULOAD; // AND
								 OR_EXT:  next_state = ALULOAD; // OR
								 ORI_EXT: next_state = ALULOAD; // XOR
								 MOV_EXT: next_state = DATAMOVE; // MOV
								 default: next_state = FETCH; 
							endcase
					  end
			
					  LD_ST_J_OP: begin
							case (opcode_ext)
								 STOR_EXT: next_state = ADDRCALC; // STOR
								 LOAD_EXT: next_state = ADDRCALC;  // LOAD
							   SNXB_EXT: next_state = SIGNEXTEND ; // SNXB
								 ZRXB_EXT: next_state = SIGNEXTEND ; // ZRXB
								 
								 SCOND_EXT: next_state = BRANCH; // Scond
								 JCOND_EXT: next_state = JUMP; // Jcond
								 JAL_EXT: next_state = JUMP; // JAL
								 TBIT_EXT: next_state = REGWRITE; // TBIT
								 TBITI_EXT: next_state = REGWRITE; // TBITI
								 LPR_EXT: next_state = REGWRITE; // LPR
								 SPR_EXT: next_state = REGWRITE; // SPR
								 default: next_state = FETCH; // DI, EI, EXCP, RETX, unused cases
							endcase
					  end
			
					  ADDI_OP: next_state = ALULOAD; // ADDI
			
					  // ADDUI_OP: next_state = ALULOAD; // ADDUI (not implemented)
			
					  // ADDCI_OP: next_state = ALULOAD; // ADDCI (not implemented)
			
					  SH_OP: next_state = SHIFT; // LSH LSHI ASHU ASHUI
			
					  SUBI_OP: next_state = ALULOAD; // SUBI
			
					  // SUBCI_OP: next_state = ALULOAD; // SUBCI (not implemented)
			
					  CMPI_OP: next_state = ALULOAD; // CMPI
			
					  BCOND_OP: next_state = BRANCH; // Bcond
			
					  MOVI_OP: next_state = DATAMOVE; // MOVI
			
					  MULI_OP: next_state = ALULOAD; // MULI
			
					  LUI_OP: next_state = IMMLOAD; // LUI
			
					  default: next_state = FETCH; // undefined opcodes
				 endcase
		
	
			  ALULOAD: 
					next_state = ALU;
					
			  ALU: 
					next_state = REGWRITE;                 // reg write-back after ALU operation	
	
			  DATAMOVE: 
					next_state = REGWRITE;                 // reg write-back after data movement
	
			  SHIFT: 
					next_state = REGWRITE;                 // reg write-back after shift operation
	
			  IMMLOAD: 
					next_state = REGWRITE;                 // REG write-back after immediate load
	
			  ADDRCALC: 
					next_state = MEMREAD;                  // go to memory read after address calculation
	
			  MEMREAD: 
					next_state = REGWRITE;                 // Write-back after memory read (load)
	
			  MEMWRITE: 
					next_state = FETCH;                    // Return to fetch after memory write (store)
	
			  JUMP: 
			   // NEED CONDITIONAL CASES HERE OR IN OUTPUT LOGIC
					next_state = FETCH;                
	
			  BRANCH: 
				// NEED CONDITIONAL CASES HERE OR IN OUTPUT LOGIC
					next_state = FETCH; 
	
			  SIGNEXTEND: 
					next_state = REGWRITE;                 // Write-back after sign extension
	
			  REGWRITE: 
					next_state = FETCH;                    // Return to fetch after register write-back
	
			  default: 
					next_state = FETCH;                    // Default to fetch state
		 endcase
	end
	

  // ********************************* 
  // Combinational 
  // *********************************

  // generate output
  always @(*) begin 
    case (present_state) 
        
      default:
    endcase
  end

endmodule
