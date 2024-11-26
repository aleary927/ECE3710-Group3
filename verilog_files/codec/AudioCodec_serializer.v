module AudioCodec_serializer #(parameter DATA_WIDTH = 16)
(
  input clk, 
  input reset_n, 
  input fifo_clr,
  input en,
  input lrclk,
  input bclk_rising_edge, 
  input bclk_falling_edge, 
  input lrclk_rising_edge, 
  input lrclk_falling_edge,

  input fifo_wr_en,
  
  input [DATA_WIDTH - 1:0] audio_data,

  output fifo_full, 
  output fifo_empty,

  output reg i2s_data
);

  // ------------------
  // Parameters 
  // ------------------ 

  localparam NULL_STATE       = 3'h0; 
  localparam START_SAMPLE     = 3'h1;
  localparam START_LEFT       = 3'h2;
  localparam TRANSFER_LEFT    = 3'h3; 
  localparam START_RIGHT      = 3'h4;
  localparam TRANSFER_RIGHT   = 3'h5;

  // -------------------- 
  // Internal Wires 
  // -------------------
  
  // data to shift out 
  reg [DATA_WIDTH - 1:0] shiftreg;

  // to hold data for current sample period
  reg [DATA_WIDTH - 1:0] sample_data; 
  
  // read from fifo
  wire [DATA_WIDTH - 1:0] fifo_data;

  // read enable for fifo, data avaiable during next clock cycle
  reg fifo_rd_en;
  reg fifo_rd_valid;

  reg [2:0] state; 
  reg [2:0] n_state;

  // -------------------- 
  // State Machine 
  // -------------------

  always @(posedge clk) begin 
    if (!reset_n) 
      state <= NULL_STATE;
    else 
      state <= n_state;
  end

  always @(*) begin 
    case (state) 
      NULL_STATE: begin 
        if (lrclk_rising_edge & bclk_falling_edge) 
          n_state = START_SAMPLE; 
        else 
          n_state = NULL_STATE;
      end 
      START_SAMPLE: n_state = START_LEFT;
      START_LEFT: n_state = TRANSFER_LEFT;
      TRANSFER_LEFT: begin 
        if (lrclk_falling_edge & bclk_falling_edge) 
          n_state = START_RIGHT; 
        else 
          n_state = TRANSFER_LEFT;
      end
      START_RIGHT: n_state = TRANSFER_RIGHT; 
      TRANSFER_RIGHT: begin 
        if (lrclk_rising_edge & bclk_falling_edge)
          n_state = START_SAMPLE;
        else 
          n_state = TRANSFER_RIGHT;
      end
      default: n_state = NULL_STATE;
    endcase
  end

  // -------------------- 
  // Sequential 
  // --------------------

  // data control
  always @(posedge clk) begin 
    if (!reset_n) begin
      shiftreg <= 0;
      sample_data <= 0;
    end
    // load new sample data
    else if (state == START_LEFT) begin 
      if (fifo_rd_valid) begin
        shiftreg <= fifo_data; 
        sample_data <= fifo_data;
      end
      else begin 
        shiftreg <= 0; 
        sample_data <= 0;
      end
    end
    // load saved sample data
    else if (state == START_RIGHT) begin 
      shiftreg <= sample_data;
    end
    else if ((state == TRANSFER_LEFT) | (state == TRANSFER_RIGHT)) begin 
      if (bclk_falling_edge)
        shiftreg <= {shiftreg[DATA_WIDTH - 2:0], 1'b0};
    end
    else begin 
      shiftreg <= 0; 
      sample_data <= 0;
    end

  end

  // output logic
  always @(posedge clk) begin 
    if (!reset_n)
      i2s_data <= 0; 
    else 
      i2s_data <= shiftreg[DATA_WIDTH - 1];
  end

  always @(posedge clk) begin 
    if (!reset_n) 
      fifo_rd_valid <= 0; 
    else if (fifo_rd_en & !fifo_empty && en) 
      fifo_rd_valid <= 1;
    else 
      fifo_rd_valid <= 0;

  end

  // --------------------- 
  // Combinational 
  // --------------------- 

  always @(*) begin 
    if (!reset_n) 
      fifo_rd_en <= 0;
    // read enable
    else if (state == START_SAMPLE) 
      fifo_rd_en <= 1;
    else 
      fifo_rd_en <= 0;

  end
  // ------------------------ 
  // Modules 
  // ------------------------ 

  // mono so only one needed
  FIFO #(DATA_WIDTH, 6) fifo ( 
    .clk(clk), 
    .reset_n(reset_n & ~fifo_clr), 
    .wr_en(fifo_wr_en), 
    .rd_en(fifo_rd_en && en), 
    .data_in(audio_data), 
    .data_out(fifo_data), 
    .full(fifo_full), 
    .empty(fifo_empty)
  );

endmodule
