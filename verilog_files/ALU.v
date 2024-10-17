module ALU #(parameter DATA_WIDTH = 16)
(
    input [DATA_WIDTH - 1:0] a,
    input [DATA_WIDTH - 1:0] b,
    input [2:0] select,
    output reg [DATA_WIDTH - 1:0] out,
    output reg C, L, F, Z, N
);

// parameters for function select
localparam ADD = 3'b000; 
localparam SUB = 3'b001; 
localparam AND = 3'b010; 
localparam OR  = 3'b011; 
localparam XOR = 3'b100; 
localparam NOT = 3'b101;

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
            // signed negative flag (negative result with no overflow, or
            // a and b both negative)
            N = (out[DATA_WIDTH - 1] & ~F) | (a[DATA_WIDTH - 1] & b[DATA_WIDTH - 1]);
        end

        SUB: begin  // subtract
            // subtract and include borrow bit as unsigned overflow
            {C, out} = a - b;
            // overflow flag
            F = (a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1] & ~out[DATA_WIDTH - 1]) | (~a[DATA_WIDTH - 1] & b[DATA_WIDTH - 1] & out[DATA_WIDTH - 1]);
            // signed negative flagt (negative resutl with no overflow, or
            // a negative and b positive)
            N = (out[DATA_WIDTH - 1] & ~F) | (a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1]);
        end

        AND: out = a & b;  // AND
        OR: out = a | b;  // OR
        XOR: out = a ^ b;  // XOR
        NOT: out = ~a;     // NOT

        //3'b110: out = a << b[3:0];  // left shift
        //3'b111: out = $signed(a) >>> b[3:0];  // Arithmetic right shift

        default: out = 0;
    endcase

    // Zero flag
    if (out == 0)
        Z = 1;

    // Less-than flag (signed compare)
    if ($unsigned(a) < $unsigned(b))
        L = 1;

end

endmodule
