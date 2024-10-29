/* 
* Module to compute new program counter value.
*/
module PC_ALU #(parameter PC_WIDTH = 21)
(
  input [PC_WIDTH - 1:0] c_pc,      // current pc
  input [PC_WIDTH - 1:0] offset,       // sign extended immediate
  input [PC_WIDTH - 1:0] target,   // absolute address
  input [1:0] addr_mode,        // addressing mode
  output reg [PC_WIDTH - 1:0] n_pc  // next pc
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
      OFFSET: n_pc = c_pc + offset;   // sign exted
      // use target for absolute
      ABSOLUTE: n_pc = target;    // zero pad
      default: n_pc = c_pc;
    endcase
  end

endmodule
