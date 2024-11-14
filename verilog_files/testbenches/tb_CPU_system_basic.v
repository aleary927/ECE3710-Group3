module tb_CPU_system_basic(); 

reg clk; 
reg [3:0] key;
reg [9:0] sw; 



CPU_system_basic sys (
.CLOCK_50(clk), 
.SW(sw),
.KEY(key)
);

initial begin 
  clk = 0; 
  forever #5 clk = ~clk;
end

initial begin 
  sw = 0; 
  key = 4'hF;
end

initial begin 
  key = 0;
#10; 
  key = 4'hF;
end

endmodule
