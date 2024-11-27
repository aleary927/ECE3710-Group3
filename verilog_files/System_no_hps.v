/*
* System without the hps instanciated, for testing everything other than music 
* streaming.
*/
module System_no_hps(
  input CLOCK_50, 

  // simple board peripherals
  input [3:0] KEY, 
  input [9:0] SW, 
  output [9:0] LEDR, 
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

  // other board peripherals 
  inout FPGA_I2C_SDAT, 
  output FPGA_I2C_SCLK, 

  input AUD_BCLK, 
  input AUD_DACLRCK, 
  output AUD_XCK, 
  output AUD_DACDAT, 

  output [7:0] VGA_R,
  output [7:0] VGA_G,
  output [7:0] VGA_B,
  output VGA_CLK,
  output VGA_BLANK_N,
  output VGA_HS,
  output VGA_SYNC_N,
  output VGA_VS,
  
  // special inputs (for drumpads)
  inout [35:0] GPIO_1
); 

  localparam CPU_ADDR_WIDTH = 16;
  localparam AUDIO_ADDR_WIDTH = 18;

  /******************** 
  * Internal wires 
  *********************/

  wire reset_n;

  // cpu connectors
  wire [15:0] mem_addr_from_cpu; 
  wire [15:0] mem_rd_data_to_cpu; 
  wire [15:0] mem_wr_data_from_cpu;
  wire cpu_wr_en;

  // port 2 memory connectors 
  wire [CPU_ADDR_WIDTH - 1:0] vga_controller_addr; 
  wire [15:0] vga_controller_data;

  // audio mixer rom signals
  wire [15:0] audio_mixer_data;
  wire [AUDIO_ADDR_WIDTH - 1:0] audio_mixer_addr;

  // codec signals
  wire [15:0] mixed_audio_data; 
  wire audio_fifo_wr_en; 
  wire audio_fifo_full;
  wire audio_fifo_empty;

  // vga wires 
  wire [15:0] VGA_hCount; 
  wire [15:0] VGA_vCount;

  // music playback control 
  wire [1:0] music_ctrl;
  wire music_pause_n; 
  wire music_reset;

  // drumpad wires
  wire [3:0] drumpads_raw;    // pre processing
  wire [3:0] drumpads_en;     // one clock cycle enable
  wire [3:0] drumpads_debounced;    // stable for some num of milliseconds
  
  /***************** 
  * Combinational 
  ******************/

  assign drumpads_raw = {GPIO_1[7], GPIO_1[5], GPIO_1[3], GPIO_1[1]};

  assign music_pause_n = music_ctrl[0]; 
  assign music_reset = music_ctrl[1];

  // for convenience
  assign reset_n = KEY[0];

  /**************** 
  * Modules
  ****************/

  // CPU 
  CPU cpu (
    .clk(CLOCK_50), 
    .reset_n(reset_n),
    .mem_rd_data(mem_rd_data_to_cpu), 
    .mem_wr_en(cpu_wr_en), 
    .mem_addr(mem_addr_from_cpu),
    .mem_wr_data(mem_wr_data_from_cpu)
  );

  // drumpad input processing
  DrumPad_input_processor #(4, 15) drumpad_proc (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .drumpads_raw(drumpads_raw), 
    .drumpads_en(drumpads_en), 
    .drumpads_debounced(drumpads_debounced)
  );

  // TODO add hCount, vCount; create interface for reading info from mem
  // vga 
  VGA vga_control (
    .clk(CLOCK_50), 
    .VGA_RED(VGA_R), 
    .VGA_GREEN(VGA_G), 
    .VGA_BLUE(VGA_B), 
    .VGA_CLK(VGA_CLK), 
    .VGA_BLANK_N(VGA_BLANK_N), 
    .VGA_HS(VGA_HS), 
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_VS(VGA_VS)
  );

  // TODO add logic to read from HPS audio stream
  // TODO add interface for waiting on reads depending on the read data valid signal
  // TODO add ability to pause and reset 
  // audio mixer/controller
  AudioMixer #(16, AUDIO_ADDR_WIDTH, 16) mixer (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .en(1'b1),
    .sample_triggers(drumpads_en), 
    .mem_rd_data(audio_mixer_data), 
    .mem_addr(audio_mixer_addr), 
    .fifo_full(audio_fifo_full), 
    .fifo_wr_en(audio_fifo_wr_en), 
    .fifo_data(mixed_audio_data)
  );
  
  // TODO add some pause logic to handle pauses smoothly
  // audio codec
  AudioCodec #(16) codec (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .reset_config_n(reset_n), 
    .en(~music_pause_n), 
    .audio_data(mixed_audio_data), 

    .I2C_SDAT(FPGA_I2C_SDAT), 
    .I2C_SCLK(FPGA_I2C_SCLK), 

    .AUD_BCLK(AUD_BCLK), 
    .AUD_DACLRCK(AUD_DACLRCK), 
    .AUD_XCK(AUD_XCK), 
    .AUD_DACDAT(AUD_DACDAT), 

    .fifo_clr(music_reset),
    .fifo_full(audio_fifo_full), 
    .fifo_empty(audio_fifo_empty), 
    .fifo_wr_en(audio_fifo_wr_en)
  );

  AudioROM #(
    "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/basic_drums.dat", 
    "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/basic_drums.dat" 
    // "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/basic_drums.dat" 
  ) 
  audio_rom (
    .clk(CLOCK_50), 
    .addr(audio_mixer_addr),
    .data(audio_mixer_data)
  );

  // Memory and IO mapping 
  MemorySystem #(CPU_ADDR_WIDTH, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/fibn.dat") mem_system (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 

    .KEY(KEY),
    .SW(SW),
    .LEDR(LEDR), 
    .HEX0(HEX0), 
    .HEX1(HEX1), 
    .HEX2(HEX2), 
    .HEX3(HEX3), 
    .HEX4(HEX4), 
    .HEX5(HEX5), 
    .drumpads(drumpads_debounced), 
    .VGA_hCount(VGA_hCount), 
    .VGA_vCount(VGA_vCount),
    .music_ctrl(music_ctrl), 

    .cpu_wr_en(cpu_wr_en), 
    .cpu_addr(mem_addr_from_cpu), 
    .cpu_wr_data(mem_wr_data_from_cpu), 
    .cpu_rd_data(mem_rd_data_to_cpu), 

    .port2_addr(vga_controller_addr), 
    .port2_rd_data(vga_controller_data)
  );

endmodule
