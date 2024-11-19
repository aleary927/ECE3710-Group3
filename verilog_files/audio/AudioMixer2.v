/*
* Reads audio samples, 
*/
module AudioMixer2  #(parameter ADDR_WIDTH)
(
  input clk, 
  input reset_n, 
  input [3:0] triggers,

  input fifo_full,

  input [15:0] mem_data,
  output reg [ADDR_WIDTH - 1:0] mem_addr,

  output fifo_wr_en,
  output [15:0] fifo_data
);

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


  localparam  [2:0]
              IDLE            = 3'h0,
              // READ            = 3'h5,
              SAMPLE0_READ    = 3'h1,
              SAMPLE1_READ    = 3'h2, 
              SAMPLE2_READ    = 3'h3, 
              SAMPLE3_READ    = 3'h4, 
              SAMPLE_WRITE    = 3'h5;

  /**********************
  * Wires and Regs 
  * *********************/

  // reg [3:0] next_sample;
  wire next_sample;
  // wire [3:0] sample_active;

  wire sample0_active, sample1_active, sample2_active, sample3_active;
  wire [ADDR_WIDTH - 1:0] sample0_addr, sample1_addr, sample2_addr, sample3_addr;

  reg [15:0] sample0_data, sample1_data, sample2_data, sample3_data;

  reg [3:0] state, n_state;
  

  /******************************* 
  * State Machine 
  * ******************************/

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
        if (!fifo_full)
          n_state = SAMPLE0_READ;
          // n_state = READ;
        else 
          n_state = IDLE;
      end
      // READ: n_state = SAMPLE_WRITE;
      SAMPLE0_READ: n_state = SAMPLE1_READ;
      SAMPLE1_READ: n_state = SAMPLE2_READ;
      SAMPLE2_READ: n_state = SAMPLE3_READ;
      SAMPLE3_READ: n_state = SAMPLE_WRITE;
      // DATA_ADD:   n_state = SAMPLE_WRITE;
      // SAMPLE_WRITE: n_state = IDLE;
      default: n_state = IDLE;
    endcase
  end

  /******************************
  * Sequential
  * ****************************/
  
  // update fifo data
  always @(posedge clk) begin 
    case (state) 
      SAMPLE0_READ: begin 
        // if (sample_active[0])
        if (sample0_active) 
          sample0_data <= mem_data;
        else 
          sample0_data <= 'h0;
        // if (sample0_active)
        //   fifo_data <= fifo_data + mem_data;
        // else 
        //   fifo_data <= fifo_data;
      end
      SAMPLE1_READ: begin 
        // if (sample_active[1])
        if (sample1_active) 
          sample1_data <= mem_data;
        else 
          sample1_data <= 'h0;
        // if (sample1_active)
        //   fifo_data <= fifo_data + mem_data;
        // else 
        //   fifo_data <= fifo_data;
      end
      SAMPLE2_READ: begin 
        // if (sample_active[2])
        if (sample2_active) 
          sample2_data <= mem_data;
        else 
          sample2_data <= 'h0;
        // if (sample2_active)
        //   fifo_data <= fifo_data + mem_data;
        // else 
        //   fifo_data <= fifo_data;
      end
      SAMPLE3_READ: begin 
        // if (sample_active[3])
        if (sample3_active) 
          sample3_data <= mem_data;
        else 
          sample3_data <= 'h0;
        // if (sample3_active)
        //   fifo_data <= fifo_data + mem_data;
        // else 
        //   fifo_data <= fifo_data;
      end
      // READ: begin 
      //   if (sample0_active)
      //     fifo_data <= mem_data;
      // end
      IDLE: begin //fifo_data <= 'h0;
        sample0_data <= 'h0; 
        sample1_data <= 'h0;
        sample2_data <= 'h0; 
        sample3_data <= 'h0;
      end
      default: ; //fifo_data <= fifo_data;
    endcase
  end


  // always @(negedge clk) begin 
  //   if (state == SAMPLE_WRITE)
  //     fifo_wr_en <= 1;
  //   else 
  //     fifo_wr_en <= 0;
  // end

  /********************************** 
  * Combinational
  * *******************************/

  assign fifo_wr_en = (state == SAMPLE_WRITE) ? 1 : 0;
  assign fifo_data = sample0_data + sample1_data + sample2_data + sample3_data;
  assign next_sample = (state == SAMPLE_WRITE);

  // // increment addresses
  // always @(negedge clk) begin 
  //   // case (state) 
  //   //   SAMPLE0_READ: next_sample = 4'b0001;
  //   //   SAMPLE1_READ: next_sample = 4'b0010;
  //   //   SAMPLE2_READ: next_sample = 4'b0100;
  //   //   SAMPLE3_READ: next_sample = 4'b1000;
  //   //   default: next_sample = 4'b0000;
  //   // endcase
  //   if (state == SAMPLE_WRITE) 
  //     next_sample <= 1'b1;
  //   else 
  //     next_sample <= 1'b0;
  // end

  // choose address
  always @(*) begin 
    case (state) 
      // READ: mem_addr = sample0_addr;
      SAMPLE0_READ: mem_addr = sample0_addr;
      SAMPLE1_READ: mem_addr = sample1_addr;
      SAMPLE2_READ: mem_addr = sample2_addr;
      SAMPLE3_READ: mem_addr = sample3_addr;
      default: mem_addr = 'h0;
    endcase
  end

  // assign mem_addr = sample0_addr;

  /***************************** 
  * Modules 
  * ***************************/

  AudioSample_tracker #(
    16, 
    SAMPLE0_BASE_ADDR, 
    SAMPLE0_END_ADDR
  ) 
  sample0_tracker (
    .clk(clk), 
    .reset_n(reset_n), 
    .trigger(triggers[0]), 
    .next_sample(next_sample), 
    .active(sample0_active), 
    .addr(sample0_addr)
  );

  AudioSample_tracker #(
    16, 
    SAMPLE1_BASE_ADDR, 
    SAMPLE1_END_ADDR
  ) 
  sample1_tracker (
    .clk(clk), 
    .reset_n(reset_n), 
    .trigger(triggers[1]), 
    .next_sample(next_sample), 
    .active(sample1_active), 
    .addr(sample1_addr)
  );

  AudioSample_tracker #(
    16, 
    SAMPLE2_BASE_ADDR, 
    SAMPLE2_END_ADDR
  ) 
  sample2_tracker (
    .clk(clk), 
    .reset_n(reset_n), 
    .trigger(triggers[2]), 
    .next_sample(next_sample), 
    .active(sample2_active), 
    .addr(sample2_addr)
  );

  AudioSample_tracker #(
    16, 
    SAMPLE3_BASE_ADDR, 
    SAMPLE3_END_ADDR
  ) 
  sample3_tracker (
    .clk(clk), 
    .reset_n(reset_n), 
    .trigger(triggers[3]), 
    .next_sample(next_sample), 
    .active(sample3_active), 
    .addr(sample3_addr)
  );

endmodule
