/*
* Module to generate timing signals for controlling a VGA interface.
*
* author: Aidan Leary
* date: 9/30/2024
*/

module vgaTiming(
  input clk50MHz, clr,
  output reg vgaClk,
  output reg hSync, vSync,
  output reg bright,
  output reg [9:0] hCount, vCount
  );

  // number of vertical and horizontal pixels 
  parameter H_PIXELS = 640;
  parameter V_PIXELS = 480;

  // horizontal timings (in clock cycles)
  parameter H_TS    = 800;
  parameter H_TDISP = 640;
  parameter H_TPW   = 96;
  parameter H_TFP   = 16;
  parameter H_TBP   = 48;
  
  // vertical timings (in lines)
  parameter V_TS    = 521;
  parameter V_TDISP = 480;
  parameter V_TPW   = 2;
  parameter V_TFP   = 10;
  parameter V_TBP   = 29;

  reg [9:0] clk_count;    // current count of 25MHz clock in current horizontal line
  reg [9:0] vRetraceLine; // current line in vertical retrace
  reg vRetrace;           // indicates if in vertical retrace

  // initial conditions
  initial begin 
    vgaClk = 0;
    clk_count = 0;
    hCount = 0;
    vCount = 0;
    bright = 0;
    hSync = 1;
    vSync = 1;
    vRetrace = 1;
    vRetraceLine = 0;
  end

  // genereate 25MHz enable
  always @(posedge clk50MHz) begin
    // reset on second rising edge
    vgaClk <= ~vgaClk;
  end

  // main logic
  always @(posedge clk50MHz) begin 
    if (!clr) begin
      clk_count <= 0;
      hCount <= 0;
      vCount <= 0;
      bright <= 0;
      hSync <= 1;
      vSync <= 1;
      vRetrace <= 1;
      vRetraceLine <= 0;
    end

    // only do logic on enable signal
    else if (vgaClk) begin

      // always count clk cycles for horizontal
      clk_count <= clk_count + 1;
      if (clk_count == H_TS - 1) 
        clk_count <= 0;
      // always do hsync pulse 
      else if (clk_count == H_TFP - 1) begin 
        hSync <= 0;
      end
      else if (clk_count == H_TFP + H_TPW - 1) begin 
        hSync <= 1;
      end

      // if not in vertical retrace
      if (!vRetrace) begin 
        // if end of line is reached (end of display)
        if (clk_count == H_TS - 1) begin
          bright <= 0;
          vCount <= vCount + 1;

          // reset vertical counter if on last row and initiate retrace
          if (vCount == V_PIXELS - 1) begin
            vCount <= 0;
            vRetrace <= 1;
          end
          // incrment vCount
          else 
            vCount <= vCount + 1;
        end
        // if end of back porch is reached
        else if (clk_count == H_TFP + H_TPW + H_TBP - 1) 
          bright <= 1;

        // increment hCount during Tdisp duration, otherwise it's 0
        if (clk_count >= H_TFP + H_TPW + H_TBP && clk_count < H_TS - 1)
          hCount <= hCount + 1;
        else 
          hCount <= 0;
      end
      // if in vertical retrace
      else begin 
        // only perform logic at ends of lines
        if (clk_count == H_TS - 1) begin
          // increment line
          vRetraceLine <= vRetraceLine + 1;

          // if end of vertical retrace
          if (vRetraceLine == V_TFP + V_TPW + V_TBP - 1) begin 
            vRetraceLine <= 0;
            vRetrace <= 0;
          end
          // if at start of pulse
          else if (vRetraceLine == V_TFP - 1)
            vSync <= 0;
          // if at end of pulse
          else if (vRetraceLine == V_TFP + V_TPW - 1) 
            vSync <= 1;
        end
      end
    end
  end
endmodule
