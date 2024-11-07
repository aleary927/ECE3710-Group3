/*
* ROM for configuration of the Wolfson WM8731 audio codec 
* aboard the DE1-Soc board.
*/
module AudioCodec_config_rom 
(
  input [3:0] addr, 
  output reg [23:0] config_data
);

  // reg 0/1 (line in settings)
  localparam LRIN_BOTH  = 1'b0, 
             RLIN_BOTH  = 1'b0,
             LIN_MUTE   = 1'b0,
             RIN_MUTE   = 1'b0,
             LINVOL     = 5'b10110,
             RINVOL     = 5'b10110; 

  // reg 2/3 (headphone out settings)
  localparam RLHP_BOTH  = 1'b0,
             LRHP_BOTH  = 1'b0,
             LZCEN      = 1'b0,
             RZCEN      = 1'b0,
             LHPVOL     = 7'b1001111,   
             RHPVOL     = 7'b1001111;   

  // reg 4 (analog path settings)
  localparam SIDEATT    = 2'b00,
             SDETONE    = 1'b0, 
             DAC_SEL    = 1'b1,    // DAC outout enabled
             BYPASS     = 1'b0, 
             INSEL      = 1'b0,
             MUTE_MIC   = 1'b1,
             MIC_BOOST  = 1'b0;

  // reg 5 (digital path settings)
  localparam  HPOR      = 1'b0, 
              DAC_MU    = 1'b0, 
              DEEMPH    = 2'b01,
              ADC_HPD   = 1'b0;

  // reg 6 (power settings)
  localparam  PWR_OFF     = 1'b0, 
              CLK_OUTPD   = 1'b0, 
              OSCPD       = 1'b0, 
              OUTPD       = 1'b0, 
              DACPD       = 1'b0, 
              ADCPD       = 1'b0, 
              MICPD       = 1'b0, 
              LINEINPD    = 1'b0;


  // reg 7 (data format settings)
  localparam  BCLK_INV  = 1'b0,
              MS        = 1'b1,         // master
              LR_SWAP   = 1'b0, 
              LRP       = 1'b0, 
              IWL       = 2'b00,    // 16 bits
              FORMAT    = 2'b01;    // left justified

  // reg 8 (sample settings)
  localparam  SR          = 4'b0110,      // 32000kHz
              CLKO_DIV2   = 1'b0, 
              CLKI_DIV2   = 1'b0, 
              BOSR        = 1'b0, 
              USB_NORM    = 1'b0;

  // reg 9 (active) 
  localparam ACTIVE = 1'b1;

  // organize each parameter into registers
  localparam  R0    = {LRIN_BOTH, LIN_MUTE, 2'b00, LINVOL},
              R1	  = {RLIN_BOTH, RIN_MUTE, 2'b00, RINVOL},
              R2	  = {LRHP_BOTH, LZCEN, LHPVOL},  
              R3	  = {RLHP_BOTH, RZCEN, RHPVOL},   
              R4	  = {1'b0, SIDEATT, SDETONE, DAC_SEL, BYPASS, INSEL, MUTE_MIC, MIC_BOOST},   
              R5	  = {4'b0000, HPOR, DAC_MU, DEEMPH, ADC_HPD},   
              R6	  = {1'b0, PWR_OFF, CLK_OUTPD, OSCPD, OUTPD, DACPD, ADCPD, MICPD, LINEINPD},
              R7	  = {1'b0, BCLK_INV, MS, LR_SWAP, LRP, IWL, FORMAT},  
              R8	  = {1'b0, CLKO_DIV2, CLKI_DIV2, SR, BOSR, USB_NORM},   
              R9	  = {8'b00000000, ACTIVE};

  always @(*) begin 
    // concat device address, reg addresss, reg data
    case(addr) 
      4'h0: config_data = {8'h34, 7'h0, R0}; 
      4'h1: config_data = {8'h34, 7'h1, R1};
      4'h2: config_data = {8'h34, 7'h2, R2};
      4'h3: config_data = {8'h34, 7'h3, R3};
      4'h4: config_data = {8'h34, 7'h4, R4};
      4'h5: config_data = {8'h34, 7'h5, R5};
      4'h6: config_data = {8'h34, 7'h6, R6};
      4'h7: config_data = {8'h34, 7'h7, R7};
      4'h8: config_data = {8'h34, 7'h8, R8};
      4'h9: config_data = {8'h34, 7'h9, R9};
      default: config_data = {8'h00, 7'h9, 9'h000};     // default is to set to not active
    endcase
  end

endmodule
