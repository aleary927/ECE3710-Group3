module DrumPad_input_processor #(parameter NUM_PADS = 4, MS = 15)
(
  input clk,
  input reset_n,
  input [NUM_PADS - 1:0] drumpads_raw,
  output [NUM_PADS - 1:0] drumpads_en,
  output [NUM_PADS - 1:0] drumpads_debounced
);

  genvar j;

  reg [NUM_PADS - 1:0] l_debounced, p_debounced;

  // detect rising edge on debounced singal
  always @(posedge clk) begin
    if (!reset_n) begin
      l_debounced <= 0;
      p_debounced <= 0;
    end
    else begin
      p_debounced <= drumpads_debounced;
      l_debounced <= p_debounced;
    end
  end

  assign drumpads_en = ((~l_debounced) & p_debounced);

  // generate debouner for each drumpad
  generate
    for (j = 0; j < NUM_PADS; j = j + 1) begin : gen_debouncers
    SimpleDebounce_ms #(MS) debounce_pad (
      .clk(clk),
      .reset_n(reset_n),
      .raw(drumpads_raw[j]),
      .debounced(drumpads_debounced[j])
    );
    end
  endgenerate


endmodule
