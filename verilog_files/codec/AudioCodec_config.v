/*
* Configures the Wolfson WM8731 audio codec aboard the DE1-SoC board 
* via I2C. 
*
* Configuration is triggered via reset.
*/
module AudioCodec_config 
(
  input clk, 
  input reset_n, 

  inout I2C_SDAT,

  output I2C_SCLK,
  output reg init_complete     // indicates that initialization is complete
);

  // -----------------------
  // Parameters 
  // ---------------------- 

  localparam TRANSFER_MASK = {8'h0, 1'h1, 8'h0, 1'h1, 8'h0, 1'h1};
  localparam MAX_REG = 9;

  // ---------------------
  // Internal Signals 
  // ---------------------

  reg [3:0] rom_address; 
  wire [23:0] rom_data;

  wire transfer_in_progress;

  wire [26:0] rom_data_i2c;
  wire start_transfer;      // tells bus controller whether to start a transfer

  // status of transfer in last and current clock cycle
  reg l_transfer_status;

  // --------------------
  // Sequential
  // -------------------
  
  // increment rom address
  always @(posedge clk) begin 
    if (!reset_n) begin
      rom_address <= 0; 
    end
    // incrmeent rom address upon completion of transfer
    else if (!transfer_in_progress & l_transfer_status)
      rom_address <= rom_address + 1'b1;
  end

  // take in transfer statuses 
  always @(posedge clk) begin
    if (!reset_n) begin
      l_transfer_status <= 0; 
    end
    else begin
      l_transfer_status <= transfer_in_progress; 
    end
  end

  always @(posedge clk) begin 
    if (!reset_n) 
      init_complete <= 0;
    else if (rom_address == (MAX_REG + 1)) 
      init_complete <= 1;
  end

  //--------------------- 
  // Combinational 
  // -------------------- 

  // bus controller should start transfer unless init complete
  assign start_transfer = ~init_complete;

  // add read bits for i2c format
  assign rom_data_i2c = {rom_data[23:16], 1'b0, rom_data[15:8], 1'b0, rom_data[7:0], 1'b0};

  // ------------------- 
  // Modules 
  // ------------------ 

  // bus controller 
  I2C_bus_controller i2c_controller (
    .clk(clk), 
    .reset_n(reset_n), 
    .start_transfer(start_transfer),
    .data_in(rom_data_i2c), 
    .transfer_mask(TRANSFER_MASK), 
    .i2c_data(I2C_SDAT), 
    .i2c_clk(I2C_SCLK),
    // .i2c_en(), 
    .data_out(), 
    .transfer_in_progress(transfer_in_progress)
  );

  // rom
  AudioCodec_config_rom config_rom (
    .addr(rom_address), 
    .config_data(rom_data)
  );

endmodule
