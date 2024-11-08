/*
* Aritmetic logic unit for CR-16 CPU. 
* 
* operations include: ADD, SUB, AND, OR, XOR, NOT, 
* LSH, ASH, MUL
*/

module ALU #(parameter DATA_WIDTH = 16)
(
    input [DATA_WIDTH - 1:0] a,
    input [DATA_WIDTH - 1:0] b,
    input [3:0] select,
    output reg [DATA_WIDTH - 1:0] out,
    output reg C, L, F, Z, N
);

wire [$clog2(DATA_WIDTH) - 1:0] shift_amount;
wire [DATA_WIDTH - 1:0] inv_b;

// parameters for function select
localparam ADD = 4'b0000; 
localparam SUB = 4'b0001; 
localparam AND = 4'b0010; 
localparam OR  = 4'b0011; 
localparam XOR = 4'b0100; 
localparam NOT = 4'b0101;
localparam LSH = 4'b0110; 
localparam ASH = 4'b0111;
localparam MUL = 4'b1000;

// if b is negative, shift amount is 2's complement inverse of b
assign inv_b = ~b + 1'b1;
assign shift_amount = b[DATA_WIDTH - 1] ? inv_b[$clog2(DATA_WIDTH) - 1:0] : b[$clog2(DATA_WIDTH) - 1:0];

always @(*) begin
    C = 0;
    L = 0;
    F = 0;
    Z = 0;
    N = 0;

    case(select)
        ADD: begin  // add
            // add and include carry bit as unsigned overflow
            {C, out} = a + b;
            // signed overflow flag (a and b same sign but result opposite)
            F = (~a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1] & out[DATA_WIDTH - 1]) | (a[DATA_WIDTH - 1] & b[DATA_WIDTH - 1] & ~out[DATA_WIDTH - 1]);
        end

        SUB: begin  // subtract
            // subtract and include borrow bit as unsigned overflow
            {C, out} = a - b;
            // overflow flag
            F = (a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1] & ~out[DATA_WIDTH - 1]) | (~a[DATA_WIDTH - 1] & b[DATA_WIDTH - 1] & out[DATA_WIDTH - 1]);
            // signed negative flag (same sign and negative result, or
            // a negative and b positive
            N = (a[DATA_WIDTH - 1] == b[DATA_WIDTH - 1] & out[DATA_WIDTH - 1]) | (a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1]);
            // unsigned less than if there is a borrow
            L = C;
        end

        AND: out = a & b;  // AND
        OR: out = a | b;  // OR
        XOR: out = a ^ b;  // XOR
        NOT: out = ~a;     // NOT
        LSH: begin 
          // if b is negative: right shfit
          if (b[DATA_WIDTH - 1])
            out = a >> shift_amount;
          // if b is positive: left shift
          else 
            out = a << shift_amount;  // left shift
        end
        ASH: begin 
          // if b is negative: right shift
          if (b[DATA_WIDTH - 1])
            out = $signed(a) >>> shift_amount;
          // if b is positive: left shift
          else
            out = a << shift_amount;
        end
        MUL: out = a * b;
        default: out = 0;
    endcase

    // Zero flag
    if (out == 0)
        Z = 1;

end

endmodule
