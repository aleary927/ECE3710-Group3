/*
* Sets output  high as soon as input goes high, output remains high for at
* least MS milliseconds.
*/
module SimpleDebounce_ms #(parameter MS = 50)
(
  input clk, 
  input reset_n, 
  input raw, 
  output debounced
);

  localparam MAX_COUNT = MS * 50000 - 1;

  reg [$clog2(MAX_COUNT) - 1:0] count;

  reg raw_stable;

  reg state, n_state;

  localparam  LOW         = 1'h0; 
  localparam  HIGH        = 1'h1;

  // state transition
  always @(posedge clk) begin 
    if (!reset_n) 
      state <= LOW;
    else 
      state <= n_state;
  end

  // next state
  always @(*) begin 
    case (state) 
      LOW: begin 
        if (raw_stable) 
          n_state = HIGH;
        else 
          n_state = LOW;
      end
      HIGH: begin 
        if (count == MAX_COUNT) 
          n_state = LOW; 
        else 
          n_state = HIGH;
      end
      default: n_state = LOW;
    endcase
  end

  // counter
  always @(posedge clk) begin 
    if (!reset_n) 
      count <= 0;
    else if (state == HIGH) 
      count <= count + 1'b1;
    else 
      count <= 0;
  end

  // stable input for each clock cycle
  always @(posedge clk) begin 
    raw_stable <= raw;
  end

  assign debounced = (state == HIGH);


endmodule
