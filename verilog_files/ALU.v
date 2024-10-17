module ALU #(parameter DATA_WIDTH = 16)
(
    input [DATA_WIDTH - 1:0] a,
    input [DATA_WIDTH - 1:0] b,
    input [2:0] select,
    output reg [DATA_WIDTH - 1:0] out,
    output reg C, L, F, Z, N
);

always @(*) begin
    C = 0;
    L = 0;
    F = 0;
    Z = 0;
    N = 0;

    case(select)
        3'b000: begin  // add
            {C, out} = a + b;
            // overflow flag
            F = (~a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1] & out[DATA_WIDTH - 1]) | (a[DATA_WIDTH - 1] & b[DATA_WIDTH - 1] & ~out[DATA_WIDTH - 1]);
            N = out[DATA_WIDTH - 1]; 
        end

        3'b001: begin  // subtract
            {C, out} = a - b;
            // overflow flag
            F = (a[DATA_WIDTH - 1] & ~b[DATA_WIDTH - 1] & ~out[DATA_WIDTH - 1]) | (~a[DATA_WIDTH - 1] & b[DATA_WIDTH - 1] & out[DATA_WIDTH - 1]);
            N = out[DATA_WIDTH - 1];
        end
        
        3'b010: out = a & b;  // AND
        3'b011: out = a | b;  // OR
        3'b100: out = a ^ b;  // XOR
        3'b101: out = ~a;     // NOT

        3'b110: out = a << b[3:0];  // left shift
        3'b111: out = $signed(a) >>> b[3:0];  // Arithmetic right shift

        default: out = 0;
    endcase

    // Zero flag
    if (out == 0)
        Z = 1;

    // Less-than flag (signed compare)
    if ($signed(a) < $signed(b))
        L = 1;

    // N flag recalculate
    if (F == 1) begin
        if (select == 3'b000) begin  // case: add
            // overflow occurs when (positive + positive), N = 0
            if (a[DATA_WIDTH - 1] == 0 && b[DATA_WIDTH - 1] == 0) begin
                N = 0;
            end
            // overflow occurs when (negative + negative), N = 1
            else if (a[DATA_WIDTH - 1] == 1 && b[DATA_WIDTH - 1] == 1) begin
                N = 1;
            end
        end
        else if (select == 3'b001) begin  // case: subtract
            // overflow occurs when (positive - negative), N = 0
            if (a[DATA_WIDTH - 1] == 0 && b[DATA_WIDTH - 1] == 1) begin
                N = 0;
            end
            // overflow occurs when (negative - positive), N = 1
            else if (a[DATA_WIDTH - 1] == 1 && b[DATA_WIDTH - 1] == 0) begin
                N = 1;
            end
        end
    end
end

endmodule
