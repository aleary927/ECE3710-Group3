module System_no_hps(
  input CLOCK_50, 

  // simple board peripherals
  input [3:0] KEY, 
  input [9:0] SW, 
  output [9:0] LEDR, 
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6,

  // other board peripherals 
  inout I2C_SDAT, 
  output I2C_SCLK, 

  input AUD_BCLK, 
  input AUD_DACLRCK, 
  output AUD_XCK, 
  output AUD_DACDAT, 

  output [7:0] VGA_R,
  output [7:0] VGA_G,
  output [7:0] VGA_B,
  VGA_CLK
  VGA_BLANK_N,
  output VGA_HS,
  VGA_SYNC_N,
  VGA_VS,
  
  // special inputs (for drumpads)
  input [35:0] GPIO_0
); 

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
  wire [17:0] mem_port2_addr;
  wire [15:0] mem_port2_rd_data;
  // connectors to memory read controller
  wire [17:0] vga_controller_addr; 
  wire vga_mem_rd_en;
  wire [17:0] audio_mixer_addr
  wire audio_mixer_rd_valid;

  // vga wires 
  wire [15:0] VGA_hCount; 
  wire [15:0] VGA_vCount;

  // music playback control 
  wire [1:0] music_ctrl;

  // drumpad wires
  wire [3:0] drumpads_raw;    // pre processing
  wire [3:0] drumpads_en;     // one clock cycle enable
  wire [3:0] drumpads_debounced;    // stable for some num of milliseconds
  
  /***************** 
  * Combinational 
  ******************/

  assign drumpads_raw = {GPIO_0[7], GPIO_0[5], GPIO_0[3], GPIO_0[1]};

  // for convenience
  assign reset_n = KEY[0];

  /**************** 
  * Modules
  ****************/

  // CPU 
  CPU cpu (
    .clk(CLOCK_50), 
    .reset_n(reset_n)
    .mem_rd_data(mem_rd_data_to_cpu), 
    .mem_wr_en(cpu_wr_en), 
    .mem_addr(mem_addr_from_cpu),
    .mem_wr_data(mem_wr_data_from_cpu)
  );

  // drumpad input processing
  DrumPad_input_processor2 #(4, 50) drumpad_proc (
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
  // TODO instanciate module
  
  // TODO add some pause logic to handle pauses smoothly
  // audio codec
  AudioCodec #(16) codec (
    .clk(CLOCK_50), 
    .reset_n(reset_n), 
    .reset_config_n(reset_n), 
    .audio_data(), 

    .I2C_SDAT(I2C_SDAT), 
    .I2C_SCLK(I2C_SCLK), 

    .AUD_BCLK(AUD_BCLK), 
    .AUD_DACLRCK(AUD_DACLRCK), 
    .AUD_XCK(AUD_XCK), 
    .AUD_DACDAT(AUD_DACDAT), 

    .fifo_full(audio_fifo_full), 
    .fifo_empty(audio_fifo_empty), 
    .fifo_wr_en(audio_fifo_wr_en)
  );

  // handle memory read conflicts between audio and VGA
  Memory_read_controller rd_controller (
    .priority_addr(vga_controller_addr), 
    .priority_rd_en(vga_mem_rd_en), 

    .secondary_addr(audio_mixer_addr), 

    .addr_to_mem(mem_port2_addr), 
    .secondary_rd_data_valid(audio_mixer_rd_valid), 
  );

  // Memory and IO mapping 
  MemorySystem #(18, "<mem_file>") mem_system (
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

    .port2_addr(mem_port2_addr), 
    .port2_rd_data(mem_port2_rd_data), 
  );

endmodule
