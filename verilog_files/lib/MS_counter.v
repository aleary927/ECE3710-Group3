module MS_counter #(parameter DATA_WIDTH = 16)
(
  input clk, 
  input reset_n,      // system reset
  input config_en,
  input user_reset, 
  input pause,
  output [DATA_WIDTH - 1:0] count
);

  reg paused; 
  wire ms_count_reset_n;
  wire enable_gen_en;
  wire en;

  // update config 
  always @(posedge clk) begin 
    if (config_en) 
      paused <= pause;
  end

  // to reset only ms on user reset
  assign ms_count_reset_n = reset_n & ~user_reset;

  assign enable_gen_en = ~paused;

  // count milliseconds
  Counter_enabled #(DATA_WIDTH) counter (
    .clk(clk), 
    .reset_n(ms_count_reset_n), 
    .en(en), 
    .count(count)
  );

  // generate enable every millisecond
  EnableGen #(50000) enable_gen (
    .clk(clk), 
    .reset_n(reset_n), 
    .en(enable_gen_en),
    .en_out(en)
  );

endmodule
