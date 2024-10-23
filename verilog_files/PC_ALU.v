/* 
* Module to compute new program counter value.
*/
module PC_ALU(
  input [20:0] c_pc,      // current pc
  input [15:0] imm,       // immediate value
  input addr_mode,        // addressing mode
  output reg [20:0] n_pc  // next pc
  );

  // opcodes 
  localparam NEXT_INSTR = 2'b00; 
  localparam OFFSET     = 2'b01; 
  localparam ABSOLUTE   = 2'b10;

  // calc new pc
  always @(*) begin 
    case (addr_mode)
      // add one for next instruction
      NEXT_INSTR: n_pc = c_pc + 1; 
      // add immediate for offset 
      OFFSET: n_pc = c_pc + imm;
      // use immediate for absolute
      ABSOLUTE: n_pc = imm;
      default: n_pc = cpc;
    endcase
  end

endmodule
