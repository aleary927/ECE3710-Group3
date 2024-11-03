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

  // ALU function selects
  localparam ADD = 4'b0000; 
  localparam SUB = 4'b0001; 
  localparam AND = 4'b0010; 
  localparam OR  = 4'b0011; 
  localparam XOR = 4'b0100; 
  localparam NOT = 4'b0101;
  localparam LSH = 4'b0110; 
  localparam ASH = 4'b0111;
  localparam MUL = 4'b1000;

  // Opcodes 
  // TODO add opcodes and opcode_exts
  
  // FSM states
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
					  4'b0000: begin
							case (opcode_ext)
								 4'b0101:  next_state = ALULOAD; // ADD
								 4'b0110:  next_state = ALULOAD; // ADDU
								 4'b0111:  next_state = ALULOAD; // ADDC
								 4'b1001:  next_state = ALULOAD; // SUB
								 4'b1010:  next_state = ALULOAD; // SUBC
								 4'b1011:  next_state = ALULOAD; // CMP
								 4'b0001:  next_state = ALULOAD; // AND
								 4'b0010:  next_state = ALULOAD; // OR
								 4'b0011: next_state = ALULOAD; // XOR
								
								 4'b1101: next_state = DATAMOVE; // MOV
								 default: next_state = FETCH; 
							endcase
					  end
			
					  4'b0100: begin
							case (opcode_ext)
								 4'b0100: next_state = ADDRCALC; // STOR
								 4'b0000: next_state = ADDRCALC;  // LOAD
								
							    4'b0010: next_state = SIGNEXTEND ; // SNXB
								 4'b0110: next_state = SIGNEXTEND ; // ZRXB
								 
								 4'b1101: next_state = BRANCH; // Scond
								 4'b1100: next_state = JUMP; // Jcond
								 4'b1000: next_state = JUMP; // JAL
								 4'b1010: next_state = REGWRITE; // TBIT
								 4'b1110: next_state = REGWRITE; // TBITI
								 4'b0001: next_state = REGWRITE; // LPR
								 4'b0101: next_state = REGWRITE; // SPR
								 default: next_state = FETCH; // DI, EI, EXCP, RETX, unused cases
							endcase
					  end
			
					  4'b0101: next_state = ALULOAD; // ADDI
			
					  4'b0110: next_state = ALULOAD; // ADDUI
			
					  4'b0111: next_state = ALULOAD; // ADDCI
			
					  4'b1000: next_state = SHIFT; // LSH LSHI ASHU ASHUI
			
					  4'b1001: next_state = ALULOAD; // SUBI
			
					  4'b1010: next_state = ALULOAD; // SUBCI
			
					  4'b1011: next_state = ALULOAD; // CMPI
			
					  4'b1100: next_state = BRANCH; // Bcond
			
					  4'b1101: next_state = DATAMOVE; // MOVI
			
					  4'b1110: next_state = ALULOAD; // MULI
			
					  4'b1111: next_state = IMMLOAD; // LUI
			
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
