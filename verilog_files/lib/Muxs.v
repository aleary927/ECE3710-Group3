/* 
* Mux definitions for convenience.
*/

// 2 inputs
module Mux2 #(parameter DATA_WIDTH = 16) 
(
  input [DATA_WIDTH - 1:0] a, b,
  input sel, 
  output [DATA_WIDTH - 1:0] out
);

  assign out = sel ? b : a; 

endmodule

// 3 inputs
module Mux3 #(parameter DATA_WIDTH = 16)
(
  input [DATA_WIDTH - 1:0] a, b, c,
  input [1:0] sel,
  output reg [DATA_WIDTH - 1:0] out
);

  always @(*) begin 
    case (sel) 
      2'b00: out = a;
      2'b01: out = b;
      2'b10: out = c;
      default: out = a;
    endcase
  end

endmodule

// 4 inputs
module Mux4 #(parameter DATA_WIDTH = 16)
(
  input [DATA_WIDTH - 1:0] a, b, c, d,
  input [1:0] sel,
  output reg [DATA_WIDTH - 1:0] out
);

  always @(*) begin 
    case (sel) 
      2'b00: out = a;
      2'b01: out = b;
      2'b10: out = c;
      2'b11: out = d;
      default: out = a; // never happens
    endcase
  end

endmodule

// 5 inputs 
module Mux5 #(parameter DATA_WIDTH = 16) 
( 
  input [DATA_WIDTH - 1:0] a, b, c, d, e, 
  input [2:0] sel, 
  output reg [DATA_WIDTH - 1:0] out
);

  always @(*) begin 
    case (sel) 
      3'h0: out = a; 
      3'h1: out = b; 
      3'h2: out = c; 
      3'h3: out = d;
      3'h4: out = e;
      default: out = a;
		endcase
  end

endmodule

// 6 inputs 
module Mux6 #(parameter DATA_WIDTH = 16) 
( 
  input [DATA_WIDTH - 1:0] a, b, c, d, e, f,
  input [2:0] sel, 
  output reg [DATA_WIDTH - 1:0] out
);

  always @(*) begin 
    case (sel) 
      3'h0: out = a; 
      3'h1: out = b; 
      3'h2: out = c; 
      3'h3: out = d;
      3'h4: out = e;
      3'h5: out = f;
      default: out = a;
		endcase
  end

endmodule
