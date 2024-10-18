module ALU #(parameter DATA_WIDTH = 16)
(
    input [DATA_WIDTH - 1:0] a,
    input [DATA_WIDTH - 1:0] b,
    input [2:0] select,
    output reg [DATA_WIDTH - 1:0] out,
    output reg C, L, F, Z, N
);

wire [$clog2(DATA_WIDTH) - 1:0] shift_amount;
wire [DATA_WIDTH - 1:0] inv_b;

// parameters for function select
localparam ADD = 3'b000; 
localparam SUB = 3'b001; 
localparam AND = 3'b010; 
localparam OR  = 3'b011; 
localparam XOR = 3'b100; 
localparam NOT = 3'b101;
localparam LSH = 3'b110; 
localparam ASH = 3'b111;

// if b is negative, shift amount is 2's complement inverse of b
assign inv_b = ~b + 1;
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

        default: out = 0;
    endcase

    // Zero flag
    if (out == 0)
        Z = 1;

end

endmodule
