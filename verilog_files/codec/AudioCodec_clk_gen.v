module AudioCodec_clk_gen #(parameter BOSR, DW)
(
  input AUD_XCK, 
  input reset_n,
  output reg AUD_BCLK, 
  output reg AUD_DACLRCK
); 

  localparam LRCK_CYC = BOSR / 2;
  localparam BCLK_CYC = (LRCK_CYC / DW) / 2; 
  
  reg [$clog2(LRCK_CYC - 1) - 1:0] lrck_count;
  reg [$clog2(BCLK_CYC -1) - 1:0] bclk_count;

  always @(posedge AUD_XCK) begin 
    if(!reset_n) begin
      AUD_DACLRCK <= 1'b0;
      lrck_count <= 'h0;
    end
    else if (lrck_count == (LRCK_CYC - 1)) begin
      AUD_DACLRCK <= ~AUD_DACLRCK;
      lrck_count <= 'h0;
    end
    else 
      lrck_count <= lrck_count + 1'b1;
  end

  always @(posedge AUD_XCK) begin 
    if (!reset_n) begin 
      AUD_BCLK <= 1'b0;
      bclk_count <= 'h0;
    end
    else if (bclk_count == (BCLK_CYC - 1)) begin
      AUD_BCLK <= ~AUD_BCLK;
      bclk_count <= 'h0;
    end
    else 
      bclk_count <= bclk_count + 1'b1;
  end

endmodule
