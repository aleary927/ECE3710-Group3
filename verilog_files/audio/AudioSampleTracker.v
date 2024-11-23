/*
* Keep track of an audio sample's address, and whether it is active 
* or idle. 
*
* Initiates a sample by taking in its address when init goes high.
* Doesn't take in a new sample until previous has finished.
*/
module AudioSampleTracker #( parameter ADDR_WIDTH)
(
  input clk,
  input reset_n,

  input [ADDR_WIDTH - 1:0] sample_end_addr, 
  input [ADDR_WIDTH - 1:0] sample_base_addr,

  input init,     // initiate sample playback
  input next_sample,  // go to next sample (next address)

  output active,      // if in playback or not
  output [ADDR_WIDTH - 1:0] addr
);

  localparam  [1:0]
              IDLE        = 2'h0,
              ACTIVE      = 2'h1;

  reg [ADDR_WIDTH - 1:0] current_addr; 
  reg [ADDR_WIDTH - 1:0] end_addr;

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
        if (init)
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

  // control addresses
  always @(posedge clk) begin 
    if (!reset_n) begin 
      current_addr <= 'h0;
      end_addr <= 'h0;
    end
    else if (state == IDLE && init) begin 
      current_addr <= sample_base_addr;
      end_addr <= sample_end_addr;
    end
    else if (state == ACTIVE && next_sample) begin 
      current_addr <= current_addr + 1'b1;
    end
  end

  assign active = (state == ACTIVE);
  assign sample_complete = (current_addr == end_addr);
  assign addr = current_addr;

endmodule
