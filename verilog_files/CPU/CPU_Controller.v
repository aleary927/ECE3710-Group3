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
  output reg [1:0] sign_ext_mode,
  output reg timer_pause_en, 
  output reg timer_reset,

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
  localparam REG_SRC_MS   = 3'h5;

  // ----- PC address modes -----
  localparam PC_INCREMENT = 2'b00; 
  localparam PC_OFFSET    = 2'b01;
  localparam PC_ABSOLUTE  = 2'b10;

  // ----- sign extension modes -----
  localparam  SIGN_EXTEND       = 2'b00;    // 2's complement sign extend
  localparam  ZERO_EXTEND       = 2'b01;       // pad with 0s in MSBs
  localparam  ALIGN_HIGH        = 2'b10;    // align on the high order bits
  localparam  SH_EXTEND         = 2'b11;    // sign extend from bit 4 for shifts

  // ----- Opcodes -----

  localparam RS_RD_OP         = 4'b0000;    // most Rsrc / Rdest based instructions (these all go by opcode extensions)
  localparam ANDI_OP          = 4'b0001;
  localparam ORI_OP           = 4'b0010;
  localparam XORI_OP          = 4'b0011;
  localparam LD_ST_J_OP       = 4'b0100;    // LOAD, STOR, Jcond, JAL
  localparam ADDI_OP          = 4'b0101;
  localparam MSCP_OP          = 4'b0110;    // this is ADDUI in regular CR16
  localparam MSCR_OP          = 4'b0111;    // this is ADDCI in regular CR16
  localparam SH_OP            = 4'b1000;    // shift instructions (this all go by opcode extensions)
  localparam SUBI_OP          = 4'b1001;
  localparam MSCG_OP          = 4'b1010;    // this is SUBCI in regular CR16
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
  localparam LSHI_EXT0        = 4'b0000;   // Left
  localparam LSHI_EXT1        = 4'b0001;    // right
  localparam ASHUI_EXT0       = 4'b0010;    // left
  localparam ASHUI_EXT1       = 4'b0011;    // right
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

    // timer signals disabled by default
    timer_reset = 0; 
    timer_pause_en = 0; 

    pc_addr_mode = PC_INCREMENT;     // incrmeent pc by default
    write_back_sel = REG_SRC_ALU;   // alu result by default
    sign_ext_mode = SIGN_EXTEND;    // regular sign extension by default

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
              default: ;  // to supress warning
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
              default: ;  // to supress warning
            endcase
          end
          // ms count pause 
          MSCP_OP: begin 
            timer_pause_en = 1;
          end
          // ms count reset 
          MSCR_OP: begin 
            timer_reset = 1;
          end
          // ms count get
          MSCG_OP: begin 
            reg_wr_en = 1;
            write_back_sel = REG_SRC_MS;
          end
          // shifts 
          SH_OP: begin 
            reg_wr_en = 1; // always write to reg on shifts
            sign_ext_mode = SH_EXTEND;
          end
          ANDI_OP: begin 
            z_f_en = 1;     // enable zero flag ??
            reg_wr_en = 1;  // write to reg
            sign_ext_mode = ZERO_EXTEND;
          end
          ORI_OP: begin 
            z_f_en = 1;  // enable zero flag ??
            reg_wr_en = 1;  // write to reg
            sign_ext_mode = ZERO_EXTEND;
          end
          XORI_OP: begin 
            z_f_en = 1;  // enable zero flag ??
            reg_wr_en = 1;  // write to reg
            sign_ext_mode = ZERO_EXTEND;
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
            sign_ext_mode = ZERO_EXTEND;
            write_back_sel = REG_SRC_IMM;   // select reg read as write back source
          end
          MULI_OP: begin 
            reg_wr_en = 1; // write to reg
            z_f_en = 1;     // enable zero flag ??
          end
          LUI_OP: begin
            reg_wr_en = 1; 
            sign_ext_mode = ALIGN_HIGH;   // align immediate on MSB
            write_back_sel = REG_SRC_IMM;
          end
          default: ; // to supress warning
        endcase
      end
      default: ;    // to supress warning
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
          LSHI_EXT0: begin 
            alu_src = 1;  // imm
            alu_sel = LSH;    
          end
          LSHI_EXT1: begin 
            alu_src = 1;  // imm
            alu_sel = LSH;    
          end
          ASHUI_EXT0: begin 
            alu_src = 1;  // imm 
            alu_sel = ASH;
          end
          ASHUI_EXT1: begin 
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
