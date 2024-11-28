/* 
* Module to extend an 8-bit immediate value to a 16-bit value.
*/
module ImmExtender(
  input [1:0] mode, 
  input [7:0] imm, 
  output reg [15:0] ext
);

  localparam  SIGN_EXTEND       = 2'b00;    // 2's complement sign extend
  localparam  ZERO_EXTEND       = 2'b01;       // pad with 0s in MSBs
  localparam  ALIGN_HIGH        = 2'b10;    // align on the high order bits
  localparam  SH_EXTEND         = 2'b11;    // sign extend from bit 4 for shifts

  always @(*) begin 
    case(mode) 
      SIGN_EXTEND:        ext = {{8{imm[7]}}, imm};
      ZERO_EXTEND:        ext = {8'b0, imm}; 
      ALIGN_HIGH:         ext = {imm, 8'b0};
      SH_EXTEND:          ext = {{12{imm[4]}}, imm[3:0]};
      default:            ext = {8'b0, imm};
    endcase
  end

endmodule
