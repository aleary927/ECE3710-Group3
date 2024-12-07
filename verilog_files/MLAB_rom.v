module MLAB_rom #(parameter DATA_WIDTH, ADDR_WIDTH, INIT_FILE) 
(
  input clk, 
  input [ADDR_WIDTH - 1:0] a,
  output reg [DATA_WIDTH - 1:0] q
); 

  (* romstyle = "MLAB" *) reg [DATA_WIDTH - 1:0] rom [ADDR_WIDTH**2 - 1:0]; /* synthesis romstyle = "MLAB" */

  initial begin 
    $readmemb(INIT_FILE, rom);
  end

  always @(posedge clk) begin 
    q <= rom[a];
  end

endmodule
