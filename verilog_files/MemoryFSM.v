/*
* Simple FSM to test Memory.
*/
module MemoryFSM(
  input clk, reset,
  input next,
  input [15:0] data_in,
  output reg wr_en, 
  output reg [9:0] addr,
  output reg [15:0] data_out
  );

  reg p_next;         // present next
  reg en;             // enable
  reg [2:0] ps, ns;     // present state, next state
  reg [15:0] data_buffer; // buffer fore read data

  // states
  parameter S0 = 3'b000; 
  parameter S1 = 3'b001; 
  parameter S2 = 3'b010; 
  parameter S3 = 3'b011; 
  parameter S4 = 3'b100;
  parameter S5 = 3'b101; 
  parameter S6 = 3'b110; 
  parameter S7 = 3'b111; 

  // initial values
  initial begin 
    p_next = 0; 
    en = 0; 
    ps = 0; 
    ns = 0; 
    wr_en = 0;
    addr = 0;
    data_out = 0;
    data_buffer = 0;
  end

  // generate enable signal
  always @(posedge clk) begin 
    // reset
    if (reset) begin
      en <= 0;
      p_next <= 0;
    end
    else begin 
      // if next high: enable is not of present next
      if (next) begin
        en <= ~p_next;
      end
      // always take in new present next
      p_next <= next;
    end
  end

  // go to next state, and take in data
  always @(posedge clk) begin 
    // reset
    if (reset) begin
      ps <= S0;
      data_buffer <= 0;
    end
    // if enable, take in next state, take in data
    else if (en) begin
      ps <= ns;
      data_buffer <= data_in;
    end

  end

  // generate next state
  always @(*) begin 
    case (ps) 
      S0: ns = S1; 
      S1: ns = S2;
      S2: ns = S3;
      S3: ns = S4;
      S4: ns = S5;
      S5: ns = S6;
      S6: ns = S7;
      S7: ns = S7;
      default: ns = S0;
    endcase
  end

  // generate output
  always @(*) begin 
    case (ns) 
      // init
      S0: begin 
        wr_en = 0; 
        data_out = 16'h0; 
        addr = 10'h0;
      end
      // write to high address
      S1: begin 
        wr_en = 1; 
        data_out = 16'h3FF; 
        addr = 10'h3FF;
      end
      // read from high address
      S2: begin 
        wr_en = 0; 
        data_out = 16'h0; 
        addr = 10'h3FF;
      end
      // write to address 0 
      S3: begin 
        wr_en = 1; 
        data_out = 16'h10;
        addr = 10'h0;
      end
      // read from address 0
      S4: begin 
        wr_en = 0; 
        data_out = 16'h0; 
        addr = 10'h0;
      end
      // write +3 to address 0
      S5: begin 
        wr_en = 1; 
        data_out = data_buffer + 16'h3; 
        addr = 10'h0;
      end
      // read address 0
      S6: begin 
        wr_en = 0; 
        data_out = 16'h0; 
        addr = 10'h0;
      end
      // read from address 0
      S7: begin 
        wr_en = 0; 
        data_out = 16'h0; 
        addr = 10'h0;
      end
      default: begin 
        wr_en = 0; 
        data_out = 0; 
        addr = 0;
      end
    endcase
  end

endmodule
