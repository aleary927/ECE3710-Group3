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
  output reg [DATA_WIDTH - 1:0] fifo_data
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
              // SAMPLE_INIT   = 3'h1,   // initiate a series of reads
              MEM_READ      = 3'h2,   // memory read in progress
              DATA_COLLECT  = 3'h3,   // collecting data from mem read, adding to sample data to fifo
              SAMPLE_WRITE  = 3'h4;   // write sample to fifo

  // ****************************** 
  // Internal Regs/Wires 
  // ***************************** 

  // table of samples currently in progress
  // | in-progress | max address | current address |
  // reg [ADDR_WIDTH * 2:0] playback_table [CONCURRENT_SAMPLES - 1:0];
  // reg [CONCURRENT_SAMPLES - 1:0] playback_valid;
  reg [ADDR_WIDTH:0] playback_table [CONCURRENT_SAMPLES - 1:0];
  reg [ADDR_WIDTH - 1:0] playback_addrs [CONCURRENT_SAMPLES - 1:0];

  reg [$clog2(CONCURRENT_SAMPLES) - 1:0] available_slot;
  reg slot_available;
  reg [$clog2(CONCURRENT_SAMPLES) - 1:0] table_line;
  reg playback_in_progress;
  wire table_line_valid;
  wire sample_complete;
  wire last_table_line;
  reg [DATA_WIDTH - 1:0] mem_data_reg;


  // states for controlling write to fifo, read, etc
  reg [2:0] state, n_state;

  // initialize regs to zeros
  integer i; 
  initial begin 
    // playback_valid = 'h0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin
      playback_addrs[i] = 'h0;
      playback_table[i] = 'h0;
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
        if (!fifo_full & playback_in_progress) 
          n_state = MEM_READ;
        else 
          n_state = IDLE;
      end
      // SAMPLE_INIT: begin 
      //   n_state = MEM_READ;
      // end
      MEM_READ: begin 
        // memory read completed
        if (1'b1) 
          n_state = DATA_COLLECT;
        else 
          n_state = MEM_READ;
      end
      DATA_COLLECT: begin 
        // final memory read complete if table line is max
        if (last_table_line) 
          n_state = SAMPLE_WRITE; 
        else 
          n_state = MEM_READ;
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

  // posedge mem read
  always @(posedge clk) begin 
    mem_data_reg <= mem_rd_data;
  end

  // increment table line
  always @(posedge clk) begin 
    if (!reset_n) 
      table_line <= 'h0; 
    else if (state == DATA_COLLECT) 
      table_line <= table_line + 1'b1;
    else if (state == IDLE) 
      table_line <= 'h0;
  end

  // collect data 
  always @(posedge clk) begin 
    if (!reset_n) 
      fifo_data <= 'h0;
    else if (state == DATA_COLLECT) begin
      // if table line valid, add to fifo data
      if (table_line_valid) begin 
        fifo_data <= fifo_data + mem_data_reg;
      end
      else 
        fifo_data <= fifo_data;
    end
    else if (state == IDLE) 
      fifo_data <= 'h0;
    else 
      fifo_data <= fifo_data;
  end

  // // increment address of sample, or reset table line
  // always @(posedge clk) begin 
  //   // do this on data collect state because it is always one clock cycle, and
  //   // it happens for every line in playback table on each new sample
  //   if ((state == DATA_COLLECT)) begin 
  //     if (table_line_valid) begin 
  //       // check if sample has completed
  //       if (sample_complete)
  //         // set invalid
  //         playback_table[table_line][ADDR_WIDTH * 2] <= 1'b0;
  //       else
  //         // go to next sample
  //         playback_table[table_line] <= {playback_table[table_line][ADDR_WIDTH * 2: ADDR_WIDTH], (playback_table[table_line][ADDR_WIDTH - 1:0] + 1'b1)};
  //       end
  //   end
  //   else if (slot_available) begin 
  //     if (sample_triggers[0])
  //       playback_table[available_slot] <= {1'b1, SAMPLE0_END_ADDR, SAMPLE0_BASE_ADDR};
  //     else if (sample_triggers[1]) 
  //       playback_table[available_slot] <= {1'b1, SAMPLE1_END_ADDR, SAMPLE1_BASE_ADDR};
  //     else if (sample_triggers[2]) 
  //       playback_table[available_slot] <= {1'b1, SAMPLE2_END_ADDR, SAMPLE2_BASE_ADDR};
  //     else if (sample_triggers[3])
  //       playback_table[available_slot] <= {1'b1, SAMPLE3_END_ADDR, SAMPLE3_BASE_ADDR};
  //   end
  // end

  // control playback address
  always @(posedge clk) begin 
    if (state == DATA_COLLECT) begin 
      if (sample_complete) 
        playback_table[table_line] <= 'h0;
      else 
        playback_addrs[table_line] <= mem_addr + 1'b1;
    end
    else if (slot_available) begin
      if (sample_triggers[0]) begin
        playback_table[available_slot] <= {1'b1, SAMPLE0_END_ADDR};
        playback_addrs[available_slot] <= SAMPLE0_BASE_ADDR;
      end
      else if (sample_triggers[1]) begin 
        playback_table[available_slot] <= {1'b1, SAMPLE1_END_ADDR};
        playback_addrs[available_slot] <= SAMPLE1_BASE_ADDR;
      end
      else if (sample_triggers[2]) begin 
        playback_table[available_slot] <= {1'b1, SAMPLE2_END_ADDR};
        playback_addrs[available_slot] <= SAMPLE2_BASE_ADDR;
      end
      else if (sample_triggers[3]) begin 
        playback_table[available_slot] <= {1'b1, SAMPLE3_END_ADDR};
        playback_addrs[available_slot] <= SAMPLE3_BASE_ADDR;
      end
    end
  end

  // control new samples
  // // control read of data from 
  // always @(posedge clk) begin 
  //   if (!reset_n) 
  //     mem_addr <= 0;
  //   else if (state == MEM_READ) begin 
  //     mem_addr <= playback_table[table_line][ADDR_WIDTH - 1:0];
  //   end
  //
  // end

  // // read from in-progress samples, add to data, increment or reset line in plackback table
  // always @(posedge clk) begin 
  //   // reset table line and fifo data
  //   if (STATE == IDLE) begin 
  //     table_line <= 0;
  //     fifo_data <= 0;
  //   end
  //   // perform reads, collect data
  //   else if (STATE == SAMPLE_READ) begin 
  //     // increment table line
  //     table_line <= table_line + 1'b1;
  //     // if current line is in progress
  //     if (playback_table[table_line][ADDR_WIDTH*2]) begin 
  //       // add to data 
  //       fifo_data <= fifo_data + 
  //       playback_table[table_line][ADDR_WIDTH - 1:0] <= 
  //     end
  //   end
  //
  // end

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
  
  // assign mem_addr = playback_table[table_line][ADDR_WIDTH - 1:0];
  assign mem_addr = playback_addrs[table_line];
  // assign table_line_valid = playback_table[table_line][ADDR_WIDTH*2];
  assign table_line_valid = (playback_table[table_line][ADDR_WIDTH] === 1'b1);
  // assign sample_complete = playback_table[table_line][ADDR_WIDTH * 2 - 1:ADDR_WIDTH] == playback_table[table_line][ADDR_WIDTH - 1:0];
  assign sample_complete = (playback_table[table_line][ADDR_WIDTH - 1:0] <= playback_addrs[table_line]);
  assign last_table_line = table_line == (CONCURRENT_SAMPLES - 1);

  // find next available playback table slot
  always @(*) begin 
    slot_available = 1'b0;
    available_slot = 'h0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin
      // if not in playback
      if (playback_table[i][ADDR_WIDTH] === 1'b0) begin
        slot_available = 1'b1; 
        available_slot = i;
      end
    end

  end

  // find if playback is in progress 
  always @(*) begin 
    playback_in_progress = 1'b0;
    for (i = 0; i < CONCURRENT_SAMPLES; i = i + 1) begin 
      if (playback_table[i][ADDR_WIDTH] === 1'b1) 
        playback_in_progress = 1'b1;
    end
  end


  // **************************** 
  // Modules 
  // ****************************




endmodule
