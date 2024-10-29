/* 
* Module to compute new program counter value.
*/
module PC_ALU(
  input [20:0] c_pc,      // current pc
  input [15:0] offset,       // sign extended immediate
  input [15:0] target,   // absolute address
  input [1:0] addr_mode,        // addressing mode
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
      OFFSET: n_pc = c_pc + {{5{offset[15]}},offset};   // sign exted
      // use immediate for absolute
      ABSOLUTE: n_pc = {5'b0,target};    // zero pad
      default: n_pc = c_pc;
    endcase
  end

endmodule
