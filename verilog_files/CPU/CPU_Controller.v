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
  output reg reg_wr_en, 
  output reg alu_src, 
  output reg [3:0] alu_sel, 
  output reg next_instr,
  output reg pc_en, 
  output reg instr_en, 
  output reg cmp_f_en, of_f_en, z_f_en, 
  output reg [1:0] pc_addr_mode, 
  output reg [2:0] write_back_sel, 

  // to memory
  output reg mem_wr_en 
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
  
  // ************************** 
  // FSM 
  // **************************
  
  // state transition
  always @(posedge clk) begin 

    if (!reset_n) 
      present_state <= NULL_STATE; 
    else 
      present_state <= next_state;
  end

  // Generate next state
	always @(*) begin 
		 case (present_state)
			  FETCH: 
          next_state = EXECUTE;
        EXECUTE: 
          next_state = FETCH;
        default:
          next_state = FETCH;
      endcase
		 // 		// next_state = DECODE;
		 //
		 //   DECODE: 
		 //
		 // 	 case (opcode)
		 // 		  RS_RD_OP: begin
		 // 				case (opcode_ext)
		 // 					 ADD_EXT:  next_state = ALULOAD; // ADD
		 // 					 // ADDU_EXT:  next_state = ALULOAD; // ADDU (not implemented)
		 // 					 // ADDC_EXT:  next_state = ALULOAD; // ADDC (not implemented)
		 // 					 SUB_EXT:  next_state = ALULOAD; // SUB
		 // 					 SUBC_EXT:  next_state = ALULOAD; // SUBC
		 // 					 CMP_EXT:  next_state = ALULOAD; // CMP
		 // 					 AND_EXT:  next_state = ALULOAD; // AND
		 // 					 OR_EXT:  next_state = ALULOAD; // OR
		 // 					 ORI_EXT: next_state = ALULOAD; // XOR
		 // 					 MOV_EXT: next_state = DATAMOVE; // MOV
		 // 					 default: next_state = FETCH; 
		 // 				endcase
		 // 		  end
		 //
		 // 		  LD_ST_J_OP: begin
		 // 				case (opcode_ext)
		 // 					 STOR_EXT: next_state = ADDRCALC; // STOR
		 // 					 LOAD_EXT: next_state = ADDRCALC;  // LOAD
		 // 				   SNXB_EXT: next_state = SIGNEXTEND ; // SNXB
		 // 					 ZRXB_EXT: next_state = SIGNEXTEND ; // ZRXB
		 //
		 // 					 SCOND_EXT: next_state = BRANCH; // Scond
		 // 					 JCOND_EXT: next_state = JUMP; // Jcond
		 // 					 JAL_EXT: next_state = JUMP; // JAL
		 // 					 TBIT_EXT: next_state = REGWRITE; // TBIT
		 // 					 TBITI_EXT: next_state = REGWRITE; // TBITI
		 // 					 LPR_EXT: next_state = REGWRITE; // LPR
		 // 					 SPR_EXT: next_state = REGWRITE; // SPR
		 // 					 default: next_state = FETCH; // DI, EI, EXCP, RETX, unused cases
		 // 				endcase
		 // 		  end
		 //
		 // 		  ADDI_OP: next_state = ALULOAD; // ADDI
		 //
		 // 		  // ADDUI_OP: next_state = ALULOAD; // ADDUI (not implemented)
		 //
		 // 		  // ADDCI_OP: next_state = ALULOAD; // ADDCI (not implemented)
		 //
		 // 		  SH_OP: next_state = SHIFT; // LSH LSHI ASHU ASHUI
		 //
		 // 		  SUBI_OP: next_state = ALULOAD; // SUBI
		 //
		 // 		  // SUBCI_OP: next_state = ALULOAD; // SUBCI (not implemented)
		 //
		 // 		  CMPI_OP: next_state = ALULOAD; // CMPI
		 //
		 // 		  BCOND_OP: next_state = BRANCH; // Bcond
		 //
		 // 		  MOVI_OP: next_state = DATAMOVE; // MOVI
		 //
		 // 		  MULI_OP: next_state = ALULOAD; // MULI
		 //
		 // 		  LUI_OP: next_state = IMMLOAD; // LUI
		 //
		 // 		  default: next_state = FETCH; // undefined opcodes
		 // 	 endcase
		 //
		 //
		 //   ALULOAD: 
		 // 		next_state = ALU;
		 //
		 //   ALU: 
		 // 		next_state = REGWRITE;                 // reg write-back after ALU operation	
		 //
		 //   DATAMOVE: 
		 // 		next_state = REGWRITE;                 // reg write-back after data movement
		 //
		 //   SHIFT: 
		 // 		next_state = REGWRITE;                 // reg write-back after shift operation
		 //
		 //   IMMLOAD: 
		 // 		next_state = REGWRITE;                 // REG write-back after immediate load
		 //
		 //   ADDRCALC: 
		 // 		next_state = MEMREAD;                  // go to memory read after address calculation
		 //
		 //   MEMREAD: 
		 // 		next_state = REGWRITE;                 // Write-back after memory read (load)
		 //
		 //   MEMWRITE: 
		 // 		next_state = FETCH;                    // Return to fetch after memory write (store)
		 //
		 //   JUMP: 
		 //    // NEED CONDITIONAL CASES HERE OR IN OUTPUT LOGIC
		 // 		next_state = FETCH;                
		 //
		 //   BRANCH: 
		 // 	// NEED CONDITIONAL CASES HERE OR IN OUTPUT LOGIC
		 // 		next_state = FETCH; 
		 //
		 //   SIGNEXTEND: 
		 // 		next_state = REGWRITE;                 // Write-back after sign extension
		 //
		 //   REGWRITE: 
		 // 		next_state = FETCH;                    // Return to fetch after register write-back
		 //
		 //   default: 
		 // 		next_state = FETCH;                    // Default to fetch state
		 // endcase
	end
	

  // ********************************* 
  // Combinational 
  // *********************************

  // control sourcing of data to and from memory, 
  // and the enablement of reg and memory writes
  always @(*) begin 
    // all regs disabled by default
    reg_wr_en = 0; 
    pc_en = 0;
    instr_en = 0; 
    
    // all flags disabled by default
    cmp_f_en = 0; 
    of_f_en = 0; 
    z_f_en = 0;

    pc_addr_mode = PC_INCREMENT;     // incrmeent pc by default
    write_back_sel = REG_SRC_ALU;   // alu result by default

    // default is use Rsrc as mem address
    next_instr = 0; 
    // default is mem write not enabled
    mem_wr_en = 0; 

    case (present_state) 
      // get data, enable instruction reg write
      FETCH: begin 
        instr_en = 1;     // take in new instruction
        next_instr = 1;   // use pc as mem address
      end
      
      // determine whether/what to write to reg file
      // determine flags to write to 
      // determine how to calculate next pc
      EXECUTE: begin 
        pc_en = 1;    // take in new pc

        case (opcode) 
          // Rsrc, Rdest instructions
          RS_RD_OP: begin
            case (opcode_ext) 
              AND_EXT: begin 
                reg_wr_en = 1;    // enable reg write
                z_f_en = 1;     // zero flag on AND instruction ??
              end
              OR_EXT: begin 
                reg_wr_en = 1;    // enable reg write
                z_f_en = 1;     // zero flag on OR instruction ??
              end
              ADD_EXT: begin 
                reg_wr_en = 1;    // enable reg write
                z_f_en = 1;     // zero flag on ADD
                of_f_en = 1; 
              end
              // enable all flags for subraction
              SUB_EXT: begin 
                reg_wr_en = 1;    // enable reg write
                z_f_en = 1; 
                of_f_en = 1; 
                cmp_f_en = 1;
              end
              // enable all flags except overflow, no reg write
              CMP_EXT: begin 
                z_f_en = 1;
                cmp_f_en = 1;
              end
              MOV_EXT: begin 
                write_back_sel = REG_SRC_REG;     // write direct from reg 
                reg_wr_en = 1;  // enable reg write
              end
              MUL_EXT: begin 
                reg_wr_en = 1;  // enable reg write
                z_f_en = 1;     // enable zero flag for MUL ??
              end
            endcase
          end
          // loads, stores, jumps
          LD_ST_J_OP: begin 
            case (opcode_ext)
              LOAD_EXT: begin 
                // select memory read data as reg input, and enable reg write
                write_back_sel = REG_SRC_MEM;
                reg_wr_en = 1;
              end
              STOR_EXT: begin
                mem_wr_en = 1;    // write to memory
              end
              JAL_EXT: begin 
                // select pc as input to reg and enable reg write
                write_back_sel = REG_SRC_PC;  
                reg_wr_en = 1;
                // select absolute addressing for next pc
                pc_addr_mode = PC_ABSOLUTE;  
              end
              JCOND_EXT: begin 
                // check comparision result, choose next pc based on result
                // comparision success: absolute address 
                // comparison not success: increment 
                pc_addr_mode = cmp_result ? PC_ABSOLUTE : PC_INCREMENT; 
              end
            endcase
          end
          // shifts 
          SH_OP: begin 
            reg_wr_en = 1; // always write to reg on shifts
          end
          ANDI_OP: begin 
            z_f_en = 1;     // enable zero flag ??
            reg_wr_en = 1;  // write to reg
          end
          ORI_OP: begin 
            z_f_en = 1;  // enable zero flag ??
            reg_wr_en = 1;  // write to reg
          end
          XORI_OP: begin 
            z_f_en = 1;  // enable zero flag ??
            reg_wr_en = 1;  // write to reg
          end
          ADDI_OP: begin 
            z_f_en = 1;  // enable zero flag ??
            of_f_en = 1;    // enable overflow flag
            reg_wr_en = 1;  // write to reg
          end
          // enable all flags
          SUBI_OP: begin 
            z_f_en = 1;  
            of_f_en = 1;
            reg_wr_en = 1;  // write to reg
          end
          // enable all flags except overflow, no reg write
          CMPI_OP: begin 
            z_f_en = 1;  
            cmp_f_en = 1;
          end
          BCOND_OP: begin 
            // check if compare successful to determine pc address 
            // if successful: use offset to calc new pc
            // if unsucessful: increment pc
            pc_addr_mode = cmp_result ? PC_OFFSET : PC_INCREMENT;  
          end
          MOVI_OP: begin 
            reg_wr_en = 1;
            // TODO this needs to be zero extended immediate
            write_back_sel = REG_SRC_IMM;   // select reg read as write back source
          end
          MULI_OP: begin 
            reg_wr_en = 1; // write to reg
            z_f_en = 1;     // enable zero flag ??
          end
          LUI_OP: begin
            // TODO this needs to be load and 8 bit shift left

          end
        endcase
      end
    endcase
  end

  // determine ALU function and source
  always @(*) begin 
    case (opcode)
      // Rsrc, Rdest instruction
      RS_RD_OP: begin
        alu_src = 0;    // take input from Rsrc

        // choose function based on opcode extension
        case (opcode_ext) 
            AND_EXT: alu_sel = AND; 
            OR_EXT: alu_sel = OR; 
            XOR_EXT: alu_sel = XOR; 
            ADD_EXT: alu_sel = ADD; 
            SUB_EXT: alu_sel = SUB; 
            CMP_EXT: alu_sel = SUB; 
            MUL_EXT: alu_sel = MUL;
            // arbitrary choice for instructions that don't use ALU (i.e. MOV)
          default: alu_sel = ADD;     
        endcase
      end
      // shifts
      SH_OP:
        // choose function and source
        case (opcode_ext) 
          LSHI_EXT: begin 
            alu_src = 1;  // imm
            alu_sel = LSH;    
          end
          ASHUI_EXT: begin 
            alu_src = 1;  // imm 
            alu_sel = ASH;
          end
          LSH_EXT: begin 
            alu_src = 0;  // Rsrc
            alu_sel = LSH;
          end
          ASHU_EXT: begin
            alu_src = 0;  // Rsrc 
            alu_sel = ASH; 
          end
          // all shifts convered, this default is arbitrary
          default: begin 
            alu_src = 0;  // Rsrc
            alu_sel = ADD;
          end
        endcase
      ANDI_OP: begin 
        alu_src = 1;  // imm 
        alu_sel = AND; 
      end
      ORI_OP: begin 
        alu_src = 1;  // imm 
        alu_sel = OR; 
      end
      XORI_OP: begin 
        alu_src = 1; // imm 
        alu_sel = XOR; 
      end
      ADDI_OP: begin 
        alu_src = 1; 
        alu_sel = ADD; 
      end
      SUBI_OP: begin 
        alu_src = 1;  // imm
        alu_sel = SUB; 
      end
      CMPI_OP: begin 
        alu_src = 1;   // imm 
        alu_sel = SUB; 
      end
      MULI_OP: begin 
        alu_src = 1;  // imm 
        alu_sel = MUL; 
      end
      // loads, stores, jumps, branches, moves don't use ALU
      default: begin 
        alu_src = 0; 
        alu_sel = ADD;
      end
    endcase
  end

endmodule
