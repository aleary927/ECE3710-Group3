/*
* Takes input from drum pads and plays samples from memory based on 
* inputs.
*/
module DrumPadDemo(
  input CLOCK_50, 
  input [3:0] KEY, 
  input [9:0] SW,

  output [9:0] LEDR,

  inout FPGA_I2C_SDAT,
  output FPGA_I2C_SCLK, 

  input AUD_BCLK, 
  input AUD_DACLRCK,
  output AUD_XCK,
  output AUD_DACDAT,
  
  input [35:0] GPIO_1,
  output [35:0] GPIO_0
); 

  wire reset_n;

  wire [15:0] fifo_data; 
  wire fifo_full;
  wire fifo_half_full;
  wire fifo_wr_en;

  wire [15:0] mem_addr; 
  wire [15:0] mem_rd_data; 

  wire [3:0] drumpads_raw; 
  wire [3:0] drumpads_rising_edge;
  wire [3:0] drumpads_debounced;
  wire [3:0] trigger;

  assign reset_n = KEY[0];

  assign trigger = drumpads_rising_edge | SW[3:0];

  assign drumpads_raw = {GPIO_1[7], GPIO_1[5], GPIO_1[3], GPIO_1[1]};
  assign LEDR[0] = trigger[0];
  assign LEDR[1] = trigger[1]; 
  assign LEDR[2] = trigger[2];
  assign LEDR[3] = trigger[3];
  assign LEDR[6] = drumpads_debounced[0]; 
  assign LEDR[7] = drumpads_debounced[1]; 
  assign LEDR[8] = drumpads_debounced[2]; 
  assign LEDR[9] = drumpads_debounced[3];

  assign GPIO_0[3] = AUD_DACLRCK;
  assign GPIO_0[4] = AUD_BCLK;
  assign GPIO_0[5] = AUD_DACDAT;
  assign GPIO_0[2] = AUD_XCK;
  assign GPIO_0[6] = fifo_wr_en;
  assign GPIO_0[0] = fifo_full;
  

  AudioCodec codec (
    .clk(CLOCK_50), 
    .reset_n(reset_n),
    .reset_config_n(KEY[1]),
    .audio_data(fifo_data), 
    .I2C_SDAT(FPGA_I2C_SDAT), 
    .I2C_SCLK(FPGA_I2C_SCLK), 
    .AUD_BCLK(AUD_BCLK), 
    .AUD_DACLRCK(AUD_DACLRCK), 
    .AUD_XCK(AUD_XCK), 
    .AUD_DACDAT(AUD_DACDAT), 
    .fifo_wr_en(fifo_wr_en), 
    .fifo_full(fifo_full),
    .fifo_empty(), 
    .fifo_half_full(fifo_half_full)
  );

  DrumPad_input_processor #(4, 15) input_proc (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .drumpads_raw(drumpads_raw), 
    .drumpads_en(drumpads_rising_edge), 
    .drumpads_debounced(drumpads_debounced)
  );

  AudioMixer #(16, 16, 16) mixer (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .sample_triggers(trigger),
    .mem_rd_data(mem_rd_data), 
    .mem_addr(mem_addr), 
    .fifo_full(fifo_full), 
    .fifo_wr_en(fifo_wr_en), 
    .fifo_data(fifo_data)
  );

  Memory  #(16, 2**16, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/basic_drums.dat") mem (
    .clk(CLOCK_50), 
    .wr_en1('h0), 
    .wr_en2('h0),
    .addr1(mem_addr), 
    .addr2('h0),
    .wr_data1('h0),
    .wr_data2('h0),
    .rd_data1(mem_rd_data),
    .rd_data2()
  );

endmodule
