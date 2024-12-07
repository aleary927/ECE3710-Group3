/* 
* A simple CPU demonstration, simply linking to on-board switches, leds, and
* buttons.
*/
module CPU_system_basic(
  input CLOCK_50,
  input [3:0] KEY, 
  input [9:0] SW,
  output [9:0] LEDR,
  output [6:0] HEX0, 
  output [6:0] HEX1, 
  output [6:0] HEX2, 
  output [6:0] HEX3, 
  output [6:0] HEX4, 
  output [6:0] HEX5 
); 

  // I/O addresses 
  localparam  KEY_ADDR      = 2**16 - 1,  // 65,535
              SW_ADDR       = 2**16 - 2,  // 65,534
              LEDR_ADDR     = 2**16 - 3,  // 65,533
              HEX_ADDR_H    = 2**16 - 4,  // 65,532
              HEX_ADDR_L    = 2**16 - 5;  // 65,531

  // internal wires 
  wire reset_n;
  wire [15:0] mem_rd_data; 
  wire mem_wr_en; 
  wire [15:0] mem_wr_data;
  wire [15:0] mem_addr;
  wire mem_rd_clk;

  reg [15:0] io_rd_data;
  wire [15:0] mem_rd_data_to_cpu;
  wire rd_data_src;

  // regs for I/O 
  reg [9:0] led_reg; 
  reg [3:0] hex0_reg, hex1_reg, hex2_reg, hex3_reg, hex4_reg, hex5_reg;

  assign reset_n = KEY[0];
  assign rd_data_src = (mem_addr >= (2**16 - 5));
  assign LEDR = led_reg; 

  // CPU 
  CPU cpu ( 
    .clk(CLOCK_50),
    .reset_n(reset_n), 
    .mem_rd_data(mem_rd_data_to_cpu), 
    .mem_addr(mem_addr),
    .mem_wr_en(mem_wr_en), 
    .mem_wr_data(mem_wr_data)
  );

  MemPLL_0002 mem_pll(
    .refclk(CLOCK_50), 
    .rst(1'b0), 
    .outclk_0(mem_rd_clk), 
    .locked()
  );

  // Memory
  Memory #(16, 2**16, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/fibn.dat") mem (
    .wr_clk(CLOCK_50),
    .rd_clk(mem_rd_clk),
    .wr_en1(mem_wr_en), 
    .addr1(mem_addr), 
    .wr_data1(mem_wr_data), 
    .rd_data1(mem_rd_data)
  );

  // select io or mem rd data
  Mux2 #(16) mem_src (
    .sel(rd_data_src),
    .a(mem_rd_data),
    .b(io_rd_data),
    .out(mem_rd_data_to_cpu)
  );

  hexTo7Seg hex0 (
    .SW(hex0_reg), 
    .Hex(HEX0)
  );
  hexTo7Seg hex1 (
    .SW(hex1_reg), 
    .Hex(HEX1)
  );
  hexTo7Seg hex2 (
    .SW(hex2_reg), 
    .Hex(HEX2)
  );
  hexTo7Seg hex3 (
    .SW(hex3_reg), 
    .Hex(HEX3)
  );
  hexTo7Seg hex4 (
    .SW(hex4_reg), 
    .Hex(HEX4)
  );
  hexTo7Seg hex5 (
    .SW(hex5_reg), 
    .Hex(HEX5)
  );

  // get I/O read data
  always @(*) begin 
    case (mem_addr)
      KEY_ADDR:
        io_rd_data <= {12'b0, ~KEY};
      SW_ADDR: 
        io_rd_data <= {6'b0, SW};
      LEDR_ADDR:
        io_rd_data <= {6'b0, led_reg};
      HEX_ADDR_H:
        io_rd_data <= {8'b0, hex5_reg, hex4_reg};
      HEX_ADDR_L: 
        io_rd_data <= {hex3_reg, hex2_reg, hex1_reg, hex0_reg};
      default: io_rd_data <= 16'b0;
    endcase
  end

  // write to leds
  always @(posedge CLOCK_50) begin 
    if (!reset_n) 
      led_reg <= 0;
    else if ((mem_addr == LEDR_ADDR) & mem_wr_en) 
      led_reg <= mem_wr_data[9:0];
  end

  // write to low hexs 
  always @(posedge CLOCK_50) begin 
    if (!reset_n) begin
      hex0_reg <= 0; 
      hex1_reg <= 0; 
      hex2_reg <= 0; 
      hex3_reg <= 0; 
    end
    else if ((mem_addr == HEX_ADDR_L) & mem_wr_en) begin
      hex0_reg <= mem_wr_data[3:0]; 
      hex1_reg <= mem_wr_data[7:4]; 
      hex2_reg <= mem_wr_data[11:8]; 
      hex3_reg <= mem_wr_data[15:12];
   end
 end

 // write to high hexs 
 always @(posedge CLOCK_50) begin 
   if (!reset_n) begin 
      hex4_reg <= 0; 
      hex5_reg <= 0;
   end
   else if ((mem_addr == HEX_ADDR_H) & mem_wr_en) begin 
     hex4_reg <= mem_wr_data[3:0]; 
     hex5_reg <= mem_wr_data[7:4];
   end

 end


endmodule
