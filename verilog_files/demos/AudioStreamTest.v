`timescale 1ns/10ps
module AudioStreamTest (
  // input clk, 
  // input reset_n, 
  // input reset_config_n,

  input CLOCK_50,
  input [3:0] KEY,
  input [9:0] SW,
  
  input AUD_BCLK, 
  input AUD_DACLRCK, 
  output AUD_DACDAT,
  output AUD_XCK,

  inout FPGA_I2C_SDAT, 
  output FPGA_I2C_SCLK, 

  inout [35:0] GPIO_0,
  inout [35:0] GPIO_1,
  output [9:0] LEDR
);

  // localparam MAX_COUNT = 2500;

  // reg [15:0] codec_data;
  // wire reset;

  // reg fifo_wr_en; 
  wire fifo_half_full;
  wire fifo_full; 
  wire fifo_empty;
  // reg fifo_wr_en;
  wire [15:0] mem_data;

  wire trigger;

  wire [15:0] addr;
  // reg en;
  // reg [$clog2(MAX_COUNT) - 1:0] count;
  // reg [15:0] addr;

  wire reset_n;
  wire reset_config_n;
  
  wire fifo_wr_en;

  // reg [4:0] five_count;
  // reg read_five;

  // always @(posedge clk) begin 
  //   codec_data <= mem_data;
  //
  //   if (!reset_n) 
  //     addr <= 0;
  //   else if (!fifo_half_full) begin
  //     fifo_wr_en <= 1;
  //     addr <= addr + 1'b1;
  //   end
  //   else begin 
  //     fifo_wr_en <= 0; 
  //     addr <= addr;
  //   end
  // end
  
  assign GPIO_0[0] = FPGA_I2C_SCLK; 
  assign GPIO_0[1] = FPGA_I2C_SDAT;
  //
  assign GPIO_0[2] = AUD_XCK;
  assign GPIO_0[3] = AUD_DACLRCK;
  assign GPIO_0[4] = AUD_BCLK; 
  assign GPIO_0[5] = AUD_DACDAT; 

  // assign GPIO_0[6] = fifo_empty; 
  // assign GPIO_0[7] = fifo_half_full; 
  assign GPIO_0[6] = fifo_full;

  // assign GPIO_0[9] = codec_data[15];
  // assign GPIO_0[10] = addr[0];

  assign LEDR[0] = GPIO_1[1];
  assign LEDR[1] = 1'b1;
  assign trigger = GPIO_1[1] | SW[0];
  assign reset_n = KEY[0]; 
  assign reset_config_n = KEY[1];

  // Modules

  AudioStreamer streamer(
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .trigger(trigger), 
    .fifo_full(fifo_half_full), 
    .addr(addr),
    .fifo_wr_en(fifo_wr_en)
  );

  AudioCodec codec (
    .clk(CLOCK_50), 
    .reset_n(reset_n),
    .reset_config_n(reset_config_n),
    // .audio_data(codec_data), 
    .audio_data(mem_data),
    .AUD_BCLK(AUD_BCLK), 
    .AUD_DACLRCK(AUD_DACLRCK), 
    .AUD_DACDAT(AUD_DACDAT),
    .AUD_XCK(AUD_XCK), 
    .I2C_SCLK(FPGA_I2C_SCLK), 
    .I2C_SDAT(FPGA_I2C_SDAT), 
    .fifo_wr_en(fifo_wr_en), 
    .fifo_half_full(fifo_half_full),
    .fifo_full(fifo_full), 
    .fifo_empty(fifo_empty)
  );

  Memory #(16, 2**16, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/drum_flute.dat") 
  mem (
    .clk(CLOCK_50), 
    .wr_en1(1'b0), 
    .wr_en2(1'b0), 
    .addr1(addr), 
    .addr2(),
    .rd_data1(mem_data),
    .rd_data2()
  );
  
endmodule
