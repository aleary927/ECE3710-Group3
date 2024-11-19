/*
* Keep track of an audio sample's address, and whether it is active 
* or idle
*/
module AudioSample_tracker
#(
  parameter ADDR_WIDTH,
             SAMPLE_BASE_ADDR,
             SAMPLE_END_ADDR
)
(
  input clk,
  input reset_n,

  input trigger,  // trigger start of audio signal
  input next_sample,  // go to next sample (next address)

  output active,      // if in playback or not
  output reg [ADDR_WIDTH - 1:0] addr
);

  localparam  [1:0]
              IDLE        = 2'h0,
              ACTIVE      = 2'h1;


  reg [1:0] state, n_state;

  wire sample_complete;

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
        if (trigger)
          n_state = ACTIVE;
        else
          n_state = IDLE;
      end
      ACTIVE: begin
        if (sample_complete)
          n_state = IDLE;
        else
          n_state = ACTIVE;
      end
      default: n_state = IDLE;
    endcase
  end

  // update address
  always @(posedge clk) begin
    case (state)
      IDLE: begin
        addr <= SAMPLE_BASE_ADDR;
      end
      ACTIVE: begin
        if (next_sample)
          addr <= addr + 1'h1;
      end
      default: addr <= SAMPLE_BASE_ADDR;
    endcase
  end

  assign active = (state == ACTIVE);
  assign sample_complete = (addr == SAMPLE_END_ADDR);

endmodule
