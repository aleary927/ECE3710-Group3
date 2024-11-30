/*
* Module that mixes audio so that it can be sent to a fifo for audio output.
* Initiates start of sample playback, reads samples from memory, mixes samples, 
* then writes them to fifo. 
*
* Next sample is initiated when fifo is not full.
*/
`define ENABLE_HPS
module AudioMixer #(parameter DATA_WIDTH = 16, ADDR_WIDTH = 18, CONCURRENT_SAMPLES = 2) 
(
  input clk, 
  input reset_n, 

  input en,

  input [3:0] sample_triggers,
  
  input [DATA_WIDTH - 1:0] mem_rd_data, 
  output [ADDR_WIDTH - 1:0] mem_addr,

`ifdef ENABLE_HPS
  input [16:0] hps_audio_data_and_parity, 
  input hps_en,
  output hps_req,
`endif

  input fifo_full, 
  output fifo_wr_en,
  output [DATA_WIDTH - 1:0] fifo_data
);

  // ************************* 
  // Parameters 
  // ************************* 

  // length of each sample
  localparam  [ADDR_WIDTH - 1:0]
              SAMPLE0_LENGTH      = 17'h17da, 
              SAMPLE1_LENGTH      = 17'h1bea, 
              SAMPLE2_LENGTH      = 17'h208a, 
              SAMPLE3_LENGTH      = 17'h12e4;
            
  // base memory addresses of each sample
  localparam  [ADDR_WIDTH - 1:0] 
              SAMPLE0_BASE_ADDR   = 2**16,
              SAMPLE1_BASE_ADDR   = SAMPLE0_BASE_ADDR + SAMPLE0_LENGTH, 
              SAMPLE2_BASE_ADDR   = SAMPLE1_BASE_ADDR + SAMPLE1_LENGTH, 
              SAMPLE3_BASE_ADDR   = SAMPLE2_BASE_ADDR + SAMPLE2_LENGTH;

  // max addr of each sample
  localparam  [ADDR_WIDTH - 1:0]
              SAMPLE0_END_ADDR    = SAMPLE0_BASE_ADDR + SAMPLE0_LENGTH - 1, 
              SAMPLE1_END_ADDR    = SAMPLE1_BASE_ADDR + SAMPLE1_LENGTH - 1, 
              SAMPLE2_END_ADDR    = SAMPLE2_BASE_ADDR + SAMPLE2_LENGTH - 1, 
              SAMPLE3_END_ADDR    = SAMPLE3_BASE_ADDR + SAMPLE3_LENGTH - 1;

  // states
  localparam  [2:0]
              IDLE          = 3'h0,   // nothing happening, fifo full
              DATA_COLLECT  = 3'h3,   // collecting data from memory and adding it up to create mixes sample 
              SAMPLE_WRITE  = 3'h4;   // write sample to fifo

  // ****************************** 
  // Internal Regs/Wires 
  // ***************************** 

  reg [ADDR_WIDTH - 1:0] sample_end_addr, sample_base_addr;

  // table of samples currently in progress
  wire [ADDR_WIDTH - 1:0] addrs [CONCURRENT_SAMPLES - 1:0];   // current address for each sample
  reg [DATA_WIDTH - 1:0] audio_data [CONCURRENT_SAMPLES - 1:0];       // audio data read from mem for each sample
  wire [CONCURRENT_SAMPLES - 1:0] playback_status;               // whether each line in table is in progress
  reg [CONCURRENT_SAMPLES - 1:0] tracker_init;

  reg [$clog2(CONCURRENT_SAMPLES - 1) - 1:0] available_slot;
  wire slot_available;
  reg [$clog2(CONCURRENT_SAMPLES - 1) - 1:0] table_line;
  wire playback_in_progress;
  wire table_line_valid;      // if current line is valid
  wire last_table_line;
  wire next_sample;

  // hps signals
`ifdef ENABLE_HPS
  reg last_sample_parity;
  wire new_sample_parity;
  reg sample_req;
  reg hps_sample_is_ready;
  wire [15:0] hps_audio_data;
`endif

  reg [DATA_WIDTH - 1:0] complete_sample;   // finished sample

  // states for controlling write to fifo, read, etc
  reg [2:0] state, n_state;

  genvar g;
  integer i; 

  // initialize data table to 0
  initial begin 
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin
      audio_data[i] = 'h0;
    end
  end

  // ************************** 
  // State Machine 
  // **************************

  // state transition
  always @(posedge clk) begin 
    if (!reset_n) 
      state <= IDLE;
    else 
      state <= n_state;
  end

  // next state 
  always @(*) begin 
    case (state) 
      IDLE: begin 
        // read data for next sample if fifo has space available
        if (!fifo_full && en) 
          n_state = DATA_COLLECT;
        else 
          n_state = IDLE;
      end
      DATA_COLLECT: begin 
        // final memory read complete if have gone through all lines in table
`ifdef ENABLE_HPS
        if (last_table_line && hps_sample_is_ready) 
`else 
        if (last_table_line)
`endif
          n_state = SAMPLE_WRITE; 
        else 
          n_state = DATA_COLLECT;
      end
      SAMPLE_WRITE: begin 
        // only takes a single clock cycle, go back to idle
        n_state = IDLE;
      end
      default: n_state = IDLE;
    endcase
  end

  // **************************** 
  // Sequential 
  // **************************** 

  // control reading of data from HPS 
`ifdef ENABLE_HPS
  always @(posedge clk) begin 
    if (!reset_n) begin 
      hps_sample_is_ready <= 1'b0;
      sample_req <= 1'b0;
    end
    // if hps not enabled, don't wait on hps sample data
    else if (!hps_en) begin 
      hps_sample_is_ready <= 1'b1;
    end
    // during idle, reset
    else if (state == IDLE) begin 
      hps_sample_is_ready <= 1'b0;
    end
    // during data collect, make request and indicate once data received
    else if (state == DATA_COLLECT) begin 
      // make sample request on first table line
      if (table_line == 'h0) begin 
        sample_req <= ~sample_req; 
      end
      // indicate that data is read once parity bit flipped
      else if (new_sample_parity != last_sample_parity) begin 
        last_sample_parity <= new_sample_parity; 
        hps_sample_is_ready <= 1'b1;
      end
    end
  end
`endif

  // increment table line
  always @(posedge clk) begin 
    if (!reset_n) 
      table_line <= 'h0; 
    else if (state == DATA_COLLECT && !last_table_line) 
      table_line <= table_line + 1'b1;
    else 
      table_line <= 'h0;
  end

  // collect data 
  always @(posedge clk) begin 
    if (state == DATA_COLLECT) begin
      // take in read data if sample in progress, else data is 0
      if (table_line_valid) begin 
        audio_data[table_line] <= mem_rd_data;
      end
      else 
        audio_data[table_line] <= 'h0;
    end
  end


  // initiate sample 
  always @(negedge clk) begin 
    if (slot_available && sample_triggers) begin 
      tracker_init[available_slot] <= 1'b1;
    end
    else 
      tracker_init <= 'h0;
  end

  //***************************** 
  // Combinational 
  // ****************************

  // select address based on trigger 
  always @(*) begin 
    if (sample_triggers[0]) begin
      sample_base_addr = SAMPLE0_BASE_ADDR; 
      sample_end_addr = SAMPLE0_END_ADDR;
    end
    else if (sample_triggers[1]) begin
      sample_base_addr = SAMPLE1_BASE_ADDR; 
      sample_end_addr = SAMPLE1_END_ADDR;
    end
    else if (sample_triggers[2]) begin
      sample_base_addr = SAMPLE2_BASE_ADDR; 
      sample_end_addr = SAMPLE2_END_ADDR;
    end
    else if (sample_triggers[3]) begin
      sample_base_addr = SAMPLE3_BASE_ADDR; 
      sample_end_addr = SAMPLE3_END_ADDR;
    end
    else begin 
      sample_base_addr = 'h0;
      sample_end_addr = 'h0;
    end
  end
  
  // assign fifo_data = complete_sample;
  assign fifo_wr_en = (state == SAMPLE_WRITE);
  
  assign mem_addr = addrs[table_line];
  assign table_line_valid = (playback_status[table_line] == 1'b1);
  assign last_table_line = (table_line >= (CONCURRENT_SAMPLES - 1));

  // outputs for hps
`ifdef ENABLE_HPS
  assign hps_req = sample_req;
  assign hps_audio_data = hps_audio_data_and_parity[15:0];
  assign new_sample_parity = hps_audio_data_and_parity[16];
`endif

  // find next available playback table slot
  always @(*) begin 
    available_slot = 'h0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin
      // if not in playback
      if (!playback_status[i]) begin
        available_slot = i;
      end
    end
  end

  // find if playback is in progress 
  assign playback_in_progress = (playback_status != 'b0);
  assign slot_available = (playback_status != {CONCURRENT_SAMPLES{1'b1}});
  assign next_sample = (state == SAMPLE_WRITE);

  // add entries of table and hps sample
  always @(*) begin 
    complete_sample = 'h0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin 
      complete_sample = complete_sample + audio_data[i];
    end
`ifdef ENABLE_HPS 
    if (hps_en)
      complete_sample = complete_sample + hps_audio_data;
`endif
  end

  // **************************** 
  // Modules 
  // ****************************

  generate 
    for (g = 0; g < CONCURRENT_SAMPLES; g = g + 1) begin : gen_sample_trackers 
      AudioSampleTracker #(ADDR_WIDTH) sample_tracker
      (
        .clk(clk), 
        .reset_n(reset_n),
        .sample_base_addr(sample_base_addr), 
        .sample_end_addr(sample_end_addr), 
        .init(tracker_init[g] && en), 
        .next_sample(next_sample), 
        .active(playback_status[g]), 
        .addr(addrs[g])
      );
    end
  endgenerate

  Ditherer dither (
    .clk(clk), 
    .reset_n(reset_n), 
    .en(fifo_wr_en), 
    .signal_in(complete_sample), 
    .signal_out(fifo_data)
  );


endmodule
