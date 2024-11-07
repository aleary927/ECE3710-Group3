/*
* This module controls the I2C bus on the 
* De1-SoC board.
*/
module I2C_bus_controller #(parameter DATA_WIDTH = 27)
(
  input clk, 
  input reset_n,          // active low reset 
  input start_transfer,   // initiates a transfer
  input [DATA_WIDTH - 1:0] data_in,          // transfer data input
  input [DATA_WIDTH - 1:0] transfer_mask,    // read/write mask

  inout i2c_data,         // serial i2c data
  output i2c_clk,         // i2c clock output

  output [DATA_WIDTH - 1:0] data_out,        // transfer data output
  output reg transfer_in_progress
);

  // ----------------
  // Parameters 
  // ---------------

  localparam SLW_CLK_COUNTER_WIDTH = 11;
  localparam COUNTER_WIDTH = 5;

  // states
  localparam IDLE = 3'h0; 
  localparam INITIALIZE = 3'h1;     // take new data in
  localparam START_BIT = 3'h2; 
  localparam TRANSFER = 3'h3;       // shift data, increment counter
  localparam STOP_BIT = 3'h4;

  // ---------------------- 
  // Internal Signals
  // ----------------------

  reg ready_for_transfer;
  wire slw_clk;           // divided clock signal

  // bit counter
  reg [COUNTER_WIDTH - 1:0] count;

  // indicates whento change states / update data
  wire toggle_data_in; 
  wire toggle_data_out;

  reg new_data;

  reg [DATA_WIDTH - 1:0] shiftreg_data;   // data to send out
  reg [DATA_WIDTH - 1:0] shiftreg_mask;   // mask for read/write

  // state regs 
  reg [2:0] state, n_state;

  // ------------------------------
  // State Machine 
  // ------------------------------

  // state transition
  always @(posedge clk) begin 
    if (!reset_n) begin 
      state <= IDLE;
    end
    else begin 
      state <= n_state;
    end
  end

  // next state logic
  always @(*) begin 
    case (state) 
      IDLE: begin 
        // condition for initialization of transfer
        if (toggle_data_in & start_transfer & ready_for_transfer) 
          n_state = INITIALIZE;
        else 
          n_state = IDLE;
      end
      INITIALIZE: begin 
        // unconditionally start bit
        n_state = START_BIT;
      end
      START_BIT: begin 
        // condition for start of transfer
        if (toggle_data_out) 
          n_state = TRANSFER;
        else 
          n_state = START_BIT;
      end
      TRANSFER: begin
        // STOP_BIT if max count reached
        if (toggle_data_out & (count == (DATA_WIDTH - 1))) 
          n_state = STOP_BIT;
        else 
          n_state = TRANSFER;
      end
      STOP_BIT: begin
        // condition for return to idle
        if (toggle_data_in) 
          n_state = IDLE;
        else 
          n_state = STOP_BIT;
      end
      default: n_state = IDLE;
    endcase
  end

  // ----------------------------
  // Sequential Logic
  // ----------------------------

  // determine if transfer is in progress
  always @(posedge clk) begin 
    if (!reset_n) 
      transfer_in_progress <= 0; 
    else if (state == INITIALIZE) 
      transfer_in_progress <= 1;
    else if (state == IDLE)
      transfer_in_progress <= 0;
  end

  // indicate when ready for transfer
  always @(posedge clk) begin 
    if (!reset_n) 
      ready_for_transfer <= 0; 
    else if ((state == IDLE) & toggle_data_in)
      ready_for_transfer <= 1;
    else if (state == INITIALIZE)
      ready_for_transfer <= 0;
  end

  // shift register logic
  always @(posedge clk) begin 
    if (!reset_n) begin 
      count <= 0; 
      shiftreg_mask <= 0; 
      shiftreg_data <= 0;
    end
    else begin
      // take in new transfer data
      if (state == INITIALIZE) begin 
        count <= 0; 
        shiftreg_data <= data_in;
        shiftreg_mask <= transfer_mask;
      end
      // increment count, shift and take in new data
      else if (toggle_data_out & (state == TRANSFER)) begin 
        count <= count + 1'b1;
        shiftreg_data <= {shiftreg_data[DATA_WIDTH - 2:0], new_data};
        shiftreg_mask <= {shiftreg_mask[DATA_WIDTH - 2:0], 1'b0};
      end
    end
  end

  // take in new data during TRANSFER state
  always @(posedge clk) begin 
    if (!reset_n) 
      new_data <= 0;
    else if (toggle_data_in & (state == TRANSFER)) 
      new_data <= i2c_data;
  end

  // -----------------------------
  // Combinational 
  // -----------------------------

  // generate i2c clock signal 
  // only output clock if state not idle
  assign i2c_clk = (state == IDLE) ? 1'b1 : slw_clk;

  // generate i2c data signal
  assign i2c_data = (state == IDLE) ? 1'b1 :    // always high on idle
                      // (state == RESTART_BIT) ? 1'b1 :   // high on restart
                        (state == TRANSFER) ?  
                          (
                            // if masked: high impedence, otherwise data
                            (shiftreg_mask[DATA_WIDTH - 1]) ? 1'bz : 
                              shiftreg_data[DATA_WIDTH - 1] 
                          ) 
                            : 1'b0;     // 0 otherwise (START_BIT and STOP_BIT)

  assign data_out = shiftreg_data;    // deserialized output data

  // -------------------------
  // Modules 
  // -------------------------

  // gerneate i2c clock
  I2C_clock_generator #(11) i2c_clk_gen (
    .clk(clk), 
    .reset_n(reset_n), 
    .slw_clk(slw_clk),
    .middle_of_high(toggle_data_in), 
    .middle_of_low(toggle_data_out)
  );

endmodule
