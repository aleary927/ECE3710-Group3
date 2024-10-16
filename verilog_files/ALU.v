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
      3'b000: begin 
            {C, out} = a + b; 
            L = (out[DATA_WIDTH - 1] == 1) ? 1 : 0;
            N = out[DATA_WIDTH - 1]; 
            F = (C && (a[DATA_WIDTH - 1] == b[DATA_WIDTH - 1]) && (out[DATA_WIDTH - 1] != a[DATA_WIDTH - 1])) ? 1 : 0; 
        end
        
      3'b001: begin 
            {C, out} = a - b; 
            L = (out[DATA_WIDTH - 1] == 1) ? 1 : 0; 
            N = out[DATA_WIDTH - 1]; 
            F = (!C && (a[DATA_WIDTH - 1] != b[DATA_WIDTH - 1]) && (out[DATA_WIDTH - 1] != a[DATA_WIDTH - 1])) ? 1 : 0; 
        end
        
      3'b010: out = a & b; 
      3'b011: out = a | b; 
      3'b100: out = a ^ b;
      3'b101: out = ~a; 

      3'b110: begin
          out = a << b[3:0];
        end
        
      3'b111: begin
          out = $signed(a) >>> b[3:0];
        end

      default: out = 0;
    endcase

    if (out[DATA_WIDTH - 1] == 1)
      N = 1;

    if (out == 0)
      Z = 1;

    if ($signed(a) < $signed(b))
      L = 1;
    
  end

endmodule
