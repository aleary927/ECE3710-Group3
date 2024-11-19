/*
* Processes inputs from drum pads. 
* 
* Generates an enable signal on rising edge, and a debounced signal.
*/
module DrumPad_input_processor #(parameter NUM_PADS = 4, parameter DEBOUNCE_MS = 10)
(
  input clk, 
  input reset_n, 

  input [NUM_PADS - 1:0] raw,

  output [NUM_PADS - 1:0] rising_edge, 
  output reg [NUM_PADS - 1:0] debounced
); 

  // PARAMETERS

  localparam MAX_COUNT = DEBOUNCE_MS * 50000 - 1;
  

  // INTERNAL REGS/WIRES

  reg [NUM_PADS - 1:0] l_raw, p_raw;

  wire [NUM_PADS - 1:0] reset_count_n; 
  wire [NUM_PADS - 1:0] en;


  // SEQUENTIAL

  always @(posedge clk) begin 
    if (!reset_n) 
      debounced <= 0;
    // set to high on rising edge
    else if (rising_edge) 
      debounced <= debounced | rising_edge;
    // reset after count is up
    else if (en) 
      debounced <= debounced ^ en;
  end

  always @(posedge clk) begin 
    if (!reset_n) begin 
      l_raw = 0; 
      p_raw = 0;
    end
    else begin
      p_raw <= raw;
      l_raw <= p_raw;
    end
  end


  // COMBINATIONAL

  assign rising_edge = ~l_raw & p_raw;
  assign reset_count_n = {4{reset_n}} & ~rising_edge;


  // MODULES

  EnableGen #(MAX_COUNT) en_gen0 (
    .clk(clk), 
    .reset_n(reset_count_n[0]), 
    .en(1'b1), 
    .en_out(en[0])
  );

  EnableGen #(MAX_COUNT) en_gen1 (
    .clk(clk), 
    .reset_n(reset_count_n[1]), 
    .en(1'b1), 
    .en_out(en[1])
  );

  EnableGen #(MAX_COUNT) en_gen2 (
    .clk(clk), 
    .reset_n(reset_count_n[2]), 
    .en(1'b1), 
    .en_out(en[2])
  );

  EnableGen#(MAX_COUNT) en_gen3 (
    .clk(clk), 
    .reset_n(reset_count_n[3]),
    .en(1'b1),
    .en_out(en[3])
  );

endmodule
