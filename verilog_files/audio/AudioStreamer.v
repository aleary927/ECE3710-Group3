/*
* Module to play audio, starts streaming on a trigger. 
*/
module AudioStreamer(
  input clk, 
  input reset_n, 
  input trigger,
  input fifo_half_full,
  output [15:0] addr,
  output reg fifo_wr_en
); 

  localparam SOUND_BASE = 16'h0000;
  localparam SOUND_LENGTH = 16'd2500;

  localparam IDLE         = 2'h0;
  localparam INIT         = 2'b1;
  localparam PLAYBACK     = 2'h2;

  reg [1:0] state;
  reg [1:0] n_state;

  reg [15:0] count;

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
          n_state = PLAYBACK;
        else 
          n_state = IDLE;
      end
      // INIT: n_state = PLAYBACK;
      PLAYBACK: begin
        if (count == (SOUND_LENGTH - 1)) 
          n_state = IDLE; 
        else 
          n_state = PLAYBACK;
      end
      default: n_state = IDLE;
    endcase
  end

  // control writing to fifo
  always @(posedge clk) begin 
    if (!reset_n) begin
      count <= 0; 
      fifo_wr_en <= 0;
    end
    // write next sample
    else if (state == PLAYBACK) begin
      if (!fifo_half_full) begin
        fifo_wr_en <= 1; 
        count <= count + 1'b1;
      end
      else begin 
        fifo_wr_en <= 0; 
        count <= count;
      end
    end
    else begin
      count <= 0;
      fifo_wr_en <= 0; 
    end
  end

  assign addr = count;
  
endmodule
