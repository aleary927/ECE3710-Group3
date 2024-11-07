/*
* Module to examine the PSR register and the comparison pneumonic, 
* and determine if comparision/branch is true or false.
*/
module Comparator 
(
input [3:0] mnemonic, 
input [15:0] psr,
output reg result
);

// comparison mnemonics
localparam EQ = 4'b0000;
localparam NE = 4'b0001;
localparam GE = 4'b1101;
localparam CS = 4'b0010; 
localparam CC = 4'b0011;
localparam HI = 4'b0100; 
localparam LS = 4'b0101;
localparam LO = 4'b1010;
localparam HS = 4'b1011;
localparam GT = 4'b0110;
localparam LE = 4'b0111; 
localparam FS = 4'b1000;
localparam FC = 4'b1001;
localparam LT = 4'b1100;
localparam UC = 4'b1110;

// flag indexs
localparam C_IND = 0;
localparam L_IND = 2;
localparam F_IND = 5;
localparam Z_IND = 6;
localparam N_IND = 7;

// extract flags
wire C, L, N, F, Z;
assign C = psr[C_IND];
assign L = psr[L_IND];
assign N = psr[N_IND];
assign F = psr[F_IND];
assign Z = psr[Z_IND];

// espressions for result by pneumonic
// these expressions are taken directly from ISA document
always @(*) begin 
  case(mnemonic)
    EQ: result = Z;
    NE: result = ~Z;
    GE: result = N | Z;
    CS: result = C;
    CC: result = ~C;
    HI: result = L;
    LS: result = ~L;
    LO: result = ~L & ~Z;
    HS: result = L | Z;
    GT: result = N;
    LE: result = ~N;
    FS: result = F;
    FC: result = ~F;
    LT: result = ~N & ~Z;
    UC: result = 1;               // always branch on unconditional
    default: result = 0;          // defalt is no branch
  endcase
end

endmodule
