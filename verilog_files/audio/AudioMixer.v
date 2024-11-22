/*
* Module that mixes audio so that it can be sent to a fifo for audio output.
* Initiates start of sample playback, reads samples from memory, mixes samples, 
* then writes them to fifo. 
*
* Next sample is initiated when fifo is not full.
*/
module AudioMixer #(parameter DATA_WIDTH = 16, ADDR_WIDTH = 18, CONCURRENT_SAMPLES = 2) 
(
  input clk, 
  input reset_n, 

  input [3:0] sample_triggers,
  
  input [DATA_WIDTH - 1:0] mem_rd_data, 
  output [ADDR_WIDTH - 1:0] mem_addr,

  input fifo_full, 
  output reg fifo_wr_en,
  output [DATA_WIDTH - 1:0] fifo_data
);

  // ************************* 
  // Parameters 
  // ************************* 

  // length of each sample
  localparam  [ADDR_WIDTH - 1:0]
              SAMPLE0_LENGTH      = 16'h17da, 
              SAMPLE1_LENGTH      = 16'h1bea, 
              SAMPLE2_LENGTH      = 16'h208a, 
              SAMPLE3_LENGTH      = 16'h12e4;
            
  // base memory addresses of each sample
  localparam  [ADDR_WIDTH - 1:0] 
              SAMPLE0_BASE_ADDR   = 0,
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

  // table of samples currently in progress
  reg [ADDR_WIDTH - 1:0] end_addrs [CONCURRENT_SAMPLES - 1:0];        // end addresses for each sample
  reg [ADDR_WIDTH - 1:0] playback_addrs [CONCURRENT_SAMPLES - 1:0];   // current address for each sample
  reg [DATA_WIDTH - 1:0] audio_data [CONCURRENT_SAMPLES - 1:0];       // audio data read from mem for each sample
  reg [CONCURRENT_SAMPLES - 1:0] playback_status;               // whether each line in table is in progress

  reg [$clog2(CONCURRENT_SAMPLES) - 1:0] available_slot;
  wire slot_available;
  reg [$clog2(CONCURRENT_SAMPLES):0] table_line;
  wire playback_in_progress;
  wire table_line_valid;
  wire sample_complete;
  wire last_table_line;

  reg [DATA_WIDTH - 1:0] complete_sample;   // finished sample

  // states for controlling write to fifo, read, etc
  reg [2:0] state, n_state;

  // initialize regs to zeros
  integer i; 
  initial begin 
    $display("number of concurrent samples: %d", CONCURRENT_SAMPLES);
    // playback_valid = 'h0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin
      playback_addrs[i] = 'h0;
      end_addrs[i] = 'h0;
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
        if (!fifo_full && playback_in_progress) 
          n_state = DATA_COLLECT;
        else 
          n_state = IDLE;
      end
      DATA_COLLECT: begin 
        // final memory read complete if have gone through all lines in table
        if (last_table_line) 
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

  // control write to fifo
  always @(posedge clk) begin 
    if (!reset_n) 
      fifo_wr_en <= 0;
    else if (state == SAMPLE_WRITE) 
      fifo_wr_en <= 1; 
    else 
      fifo_wr_en <= 0;
  end

  // increment table line
  always @(posedge clk) begin 
    if (!reset_n) 
      table_line <= 'h0; 
    else if (state == DATA_COLLECT) 
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

  // increment playback addresses 
  always@(posedge clk) begin 
    
    // determine if sample ended during data collect state
    if ((state == DATA_COLLECT) && sample_complete) begin 
      playback_status[table_line] <= 1'b0;
    end
    // increment in sample write state
    else if (state == SAMPLE_WRITE) begin 
      for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin 
        playback_addrs[i] <= playback_addrs[i] + 1'b1;
      end
    end
    // otherwise take in new samples (in idle)
    else if (slot_available && sample_triggers) begin 
      // if (sample_triggers) begin
        playback_status[available_slot] <= 1'b1;
        end_addrs[available_slot] <= SAMPLE0_END_ADDR;
        playback_addrs[available_slot] <= SAMPLE0_BASE_ADDR;
      // end
      // else if (sample_triggers[1]) begin 
      //   playback_status[available_slot] <= 1'b1;
      //   end_addrs[available_slot] <= SAMPLE1_END_ADDR;
      //   playback_addrs[available_slot] <= SAMPLE1_BASE_ADDR;
      // end
      // else if (sample_triggers[2]) begin 
      //   playback_status[available_slot] <= 1'b1;
      //   end_addrs[available_slot] <= SAMPLE2_END_ADDR;
      //   playback_addrs[available_slot] <= SAMPLE2_BASE_ADDR;
      // end
      // else if (sample_triggers[3]) begin 
      //   playback_status[available_slot] <= 1'b1;
      //   end_addrs[available_slot] <= SAMPLE3_END_ADDR;
      //   playback_addrs[available_slot] <= SAMPLE3_BASE_ADDR;
      // end
    end
  end

  // potential sub state machine states 
  // NULL or IDLE (main state machine not in SAMPLE_READ)
  // READ_DATA (set address, wait for data to come back)
  // COLLECT_DATA (add data to running sample total)
  // SAMPLE_FINISHED (indicates that data is ready for fifo)

  // during read: have to wait for every in-progress sample to complete its
  // read, adding up the read values as they progress 
  // OR could check every sample controller every time
  
  // when sample triggered: assign its base address and end address to
  // a playback controller

  // always have to know what the next available playback controller is

  // have to keep track of whether there are any available sample
  // controllers

  //***************************** 
  // Combintional 
  // ****************************
  
  assign fifo_data = complete_sample;
  
  assign mem_addr = playback_addrs[table_line];
  assign table_line_valid = (playback_status[table_line] == 1'b1);
  assign sample_complete = (playback_addrs[table_line] == end_addrs[table_line]);
  assign last_table_line = (table_line >= (CONCURRENT_SAMPLES - 1));

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

  // add entries of table 
  always @(*) begin 
    complete_sample = 'h0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin 
      complete_sample = complete_sample + audio_data[i];
    end
  end

  // **************************** 
  // Modules 
  // ****************************

endmodule
