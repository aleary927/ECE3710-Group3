/* 
* Controls sending audio data to the Wolfson WM8731 audo codec 
* on the DE1-SoC board, and configures the chip on reset.
*
* This module is setup for mono audio.
*/
module AudioCodec #(parameter DATA_WIDTH = 16)
(
  input clk, 
  input reset_n, 

  // input reset_config_n,
  input en,

  input [DATA_WIDTH - 1:0] audio_data,
  
  // I2C interface
  inout I2C_SDAT, 
  output I2C_SCLK,

  // codec's I2S interface
  // input AUD_ADCDAT,
  inout AUD_BCLK, 
  inout AUD_DACLRCK, 
  // input AUD_ADCLRCK,
  output AUD_XCK, 
  output AUD_DACDAT,

  output fifo_full, 
  output fifo_empty,

  input fifo_clr,
  input fifo_wr_en
);

  // ---------------
  // Internal Wires 
  // ---------------
    
  wire bclk_rising_edge; 
  wire bclk_falling_edge; 
  wire lrclk_rising_edge;
  wire lrclk_falling_edge; 
  // wire reset;
  wire init_complete;
  wire reset_config_n;
  wire pll_not_locked;

  // -------------------- 
  // Combinational Logic 
  // --------------------

  // convert to active high

  assign reset_config_n = ~pll_not_locked;

  // -------------- 
  // Modules 
  // -------------- 

  AudioCodec_clk_gen #(384, 16)  clk_gen (
    .AUD_XCK(AUD_XCK), 
    .reset_n(reset_n), 
    .AUD_BCLK(AUD_BCLK), 
    .AUD_DACLRCK(AUD_DACLRCK)
  );

  AudioPLL codec_pll (
    .audio_clk_clk(AUD_XCK), 
    .ref_clk_clk(clk),
    .ref_reset_reset(1'b0), 
    .reset_source_reset(pll_not_locked)
  );

  AudioCodec_config codec_config (
    .clk(clk), 
    .reset_n(reset_config_n), 
    .I2C_SDAT(I2C_SDAT), 
    .I2C_SCLK(I2C_SCLK),
    .init_complete(init_complete)
  );

  EdgeDetect bclk_edge_detect (
    .clk(clk), 
    .reset_n(reset_n), 
    .test_clk(AUD_BCLK), 
    .rising_edge(bclk_rising_edge), 
    .falling_edge(bclk_falling_edge)
  );

  EdgeDetect lrclk_edge_detect ( 
    .clk(clk), 
    .reset_n(reset_n), 
    .test_clk(AUD_DACLRCK), 
    .rising_edge(lrclk_rising_edge), 
    .falling_edge(lrclk_falling_edge)
  );

  AudioCodec_serializer #(DATA_WIDTH) serializer
  (
    .clk(clk), 
    .reset_n(reset_n), 
    .fifo_clr(fifo_clr),
    .en(en),
    .lrclk(AUD_DACLRCK),
    .bclk_rising_edge(bclk_rising_edge), 
    .bclk_falling_edge(bclk_falling_edge),
    .lrclk_rising_edge(lrclk_rising_edge),
    .lrclk_falling_edge(lrclk_falling_edge),
    .audio_data(audio_data),
    .fifo_wr_en(fifo_wr_en), 
    .fifo_full(fifo_full), 
    .fifo_empty(fifo_empty),
    .i2s_data(AUD_DACDAT)
  );

endmodule
