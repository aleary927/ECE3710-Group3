	module VGA (
    input clk,
    input reset,       
    input [15:0] memory_read_data,   // Data read from memory
    output [7:0] VGA_RED, VGA_GREEN, VGA_BLUE,
    output VGA_CLK,                 // VGA pixel clock (25MHz)
    output VGA_BLANK_N,             // Active-low blanking signal
    output VGA_HS,                  // Horizontal sync output
    output VGA_SYNC_N,              // Assign low
    output VGA_VS,                  // Vertical sync output
    output [9:0] hCount, vCount,
    output [15:0] memory_address,    // Address to read from memory
    output memory_read_enable       // Enable signal for memory reads
);

    // Signals for VGA timing and synchronization
	 // END OF LANE AT 450
	 
	 parameter STARTING = 16'd65250; // Change depending <--
   parameter SCORE_ADDR = STARTING + 32;

   localparam IDLE = 2'h0; 
   localparam READ_TILES = 2'h1;
   localparam READ_SCORE = 2'h2;


    wire hSync, vSync, bright;
    wire En;
	
	wire [3:0] rgb; 

   // COLORS ARE STORED IN THE UPPER 4 BITS OF STARTING ADDRESS PER BLOCK 
    reg [4:0] counter;    /// 16 POSSIBLE BLOCKS, 4 PER LANE AT A TIME   
	 
    reg read_done;             

    wire tile_read_enable; 
    wire score_read_enable;
    wire start_memory_reads;

    reg [1:0] state, n_state;

    always @(posedge clk) begin 
      if (reset) 
        state <= IDLE;
      else 
        state <= n_state;
    end

    always @(*) begin 
      case(state) 
        IDLE: begin 
          if (start_memory_reads) 
            n_state = READ_TILES; 
          else 
            n_state = IDLE;
        end
        READ_TILES: begin 
          if (counter == 31) 
            n_state = READ_SCORE; 
          else 
            n_state = READ_TILES;
        end
        READ_SCORE: begin 
          n_state = IDLE;
        end
        default: n_state = IDLE;
      endcase
    end
		
	 always @(posedge clk) begin
    if (reset) begin
        counter <= 0;
    end 
    else if (tile_read_enable) begin // Start memory reads
      counter <= counter + 1;
    end
    else 
      counter <= 'h0;
end


    assign memory_address = tile_read_enable ? (STARTING + counter) : SCORE_ADDR; 

    assign tile_read_enable = (state == READ_TILES);
    assign score_read_enable = (state == READ_SCORE);

    assign start_memory_reads = (vCount == 0) && (hCount == 0) && bright; 


    // Assign VGA signals
    assign VGA_CLK = En;
    assign VGA_SYNC_N = 1'b0;
    assign VGA_BLANK_N = bright;
    assign VGA_HS = hSync;
    assign VGA_VS = vSync;
    assign VGA_RED = {8{rgb[2]}};
    assign VGA_GREEN = {8{rgb[1]}};
    assign VGA_BLUE = {8{rgb[0]}};

    
    // vgaControl vgaInst (
    //     .clk(clk),
    //     .clr(1'b1),
    //     .hSync(hSync),
    //     .vSync(vSync),
    //     .bright(bright),
    //     .hCount(hCount),
    //     .vCount(vCount),
    //     .En(En)
    // );


    vgaTiming vga (
      .clk50MHz(clk), 
      .clr(1'b1), 
      .hSync(hSync),
      .vSync(vSync),
      .bright(bright),
      .hCount(hCount),
      .vCount(vCount),
      .vgaClk(En)
    );

    
	bitGen_Glyph glyph_inst (
		 .clk(clk),
		 .h_count(hCount),
		 .v_count(vCount),
		 .memory_trans(memory_read_data), 
     .tile_read_enable(tile_read_enable),
     .score_read_enable(score_read_enable),
		 .counter(counter), 
		 .rgb(rgb)
	);



endmodule

	
	



	module bitGen_Glyph (
    input clk,                
    input [9:0] h_count,      // Current pixel x-coordinate
    input [9:0] v_count,      // Current pixel y-coordinate
   input tile_read_enable, 
   input score_read_enable,
	 input [15:0] memory_trans, 
	 input [4:0] counter, 
    output reg [2:0] rgb       // RGB output, 
);

    // Parameters for screen and lane dimensions
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter NUM_LANES = 6;                
    parameter LANE_WIDTH = SCREEN_WIDTH / NUM_LANES; // Width of each lane
    parameter LINE_WIDTH = 2;                 
    parameter BLOCK_LENGTH = 90; 
	 
	 // 16 blocks total, 2 y vals per block colors are the upper bits of the y - starter 
	 reg [15:0] blocks_reg [31:0]; 
	 integer i;
	 integer j; 
	 integer k; 
	 integer t; 
	 integer l; 

   reg [11:0] current_score;
	 
	 
	   parameter CHAR_WIDTH = 16;  // Width of a single character
		parameter CHAR_HEIGHT = 12; // Height of a single character
		parameter START_X = 537;    // Starting x-coordinate for "RHYTHM GAME"
		parameter START_Y = 48;     // Starting y-coordinate for "RHYTHM GAME"
		
		// Glyph ROM instantiation
		wire [11:0] glyph_pixels;
		reg [4:0] char_code;
		wire [3:0] row_index;
		glyph_rom glyph_instance(
        .clk(clk),
			 .char(char_code),
			 .row(row_index),
			 .pixels(glyph_pixels)
		);
	

			  // Manual assignment of blocks_reg
    always @(posedge clk) begin
      if (tile_read_enable)
        blocks_reg[counter] <= memory_trans;   
    end

    always @(posedge clk) begin 
      if (score_read_enable) 
        current_score <= memory_trans[11:0];
    end
	 

 
	 wire [3:0] thousands, hundreds, tens, units;
   wire [3:0] char_column;

     
    always @(*) begin
      char_code = 'b0;
        // START OF BACKGROUND 
        rgb = 3'b000; // Black
        
		if (h_count < 106) begin

		case ((h_count + v_count) % 3)
        0: rgb = 3'b000; 
        1: rgb = 3'b100; // Green
        2: rgb = 3'b001; // Blue
        default: rgb = 3'b000; 
		endcase
		end
        
        if ((h_count >= 106 && h_count < 108) ||
            (h_count >= 212 && h_count < 214) ||
            (h_count >= 318 && h_count < 320) ||
            (h_count >= 424 && h_count < 426) ||
            (h_count >= 528 && h_count < 530)) begin
            rgb = 3'b111; // White
        end
        		  
			   // End of lane 1
			  if (h_count >= 108 && h_count < 212 && v_count >= 450) begin
					// if(tile_hit[0]) rgb = 3'b111;  
					//
					//  else 
             rgb = 3'b100;
				end
				// End of lane 2
				else if (h_count >= 214 && h_count < 318 && v_count >= 450) begin
					// if(tile_hit[1]) rgb = 3'b111; 
					// else  
            rgb = 3'b101;
				end
				// End of lane 3
				else if (h_count >= 320 && h_count < 424 && v_count >= 450) begin
					 // if(tile_hit[2]) rgb = 3'b111;
					 // else 
             rgb = 3'b010;
				end
				// End of lane 4
				else if (h_count >= 426 && h_count < 528 && v_count >= 450) begin
					 // if(tile_hit[3]) rgb = 3'b111;
					 // else 
             rgb = 3'b110;
				end

				 
				 
			 // Background right
				if (h_count >= 530) begin
					 if(v_count >= 38 && v_count < START_Y && h_count < 637) begin 
							rgb = 3'b000; 
					 end
					 else if (v_count >= START_Y && v_count < START_Y + CHAR_HEIGHT && h_count >= 535 && h_count < 637) begin
						  // Calculate row and column within the glyph
						  // row_index = (v_count - START_Y) % 12;//CHAR_HEIGHT;
						  // char_column = (h_count - START_X) / (CHAR_WIDTH);//CHAR_WIDTH;
						  
						  // Map characters to "RHYTHM"
						  case (char_column)
								0: char_code = 5'd10; // 'R'
								1: char_code = 5'd11; // 'H'
								2: char_code = 5'd12; // 'Y'
								3: char_code = 5'd13; // 'T'
								4: char_code = 5'd11; // 'H'
								5: char_code = 5'd14; // 'M'
								default: char_code = 5'd19; // Blank space
						  endcase
						  
						  // Determine pixel color based on glyph ROM
						  if (glyph_pixels[CHAR_WIDTH - 1 - ((h_count - START_X) % CHAR_WIDTH)]) begin
								rgb = 3'b100; // White for glyph pixels
						  end
					 end
					 
					 // Second row: "SCORE"
					 else if (v_count >= START_Y + CHAR_HEIGHT && v_count < START_Y + (2* CHAR_HEIGHT)&& h_count >= 535 && h_count < 637) begin
						  // Calculate row and column within the glyph
						  // row_index = (v_count - START_Y) % CHAR_HEIGHT;
						  // char_column = (h_count - START_X) / (CHAR_WIDTH); //CHAR_WIDTH;
						  
						  // Map characters to "GAME"
						  case (char_column)
								0: char_code = 5'd15; // 's'
								1: char_code = 5'd16; // 'c'
								2: char_code = 5'd17; // 'o'
								3: char_code = 5'd10; // 'r'
								4: char_code = 5'd18; // 'e'
								default: char_code = 5'd19; // Blank space
						  endcase
						  
						  // Determine pixel color based on glyph ROM
						  if (glyph_pixels[CHAR_WIDTH - 1 - ((h_count - START_X) % CHAR_WIDTH)]) begin
								rgb = 3'b110; // White for glyph pixels
						  end
					 end
					 	 // Third row: numbers
					 else if (v_count >= START_Y + (2*CHAR_HEIGHT) && v_count < START_Y + (3* CHAR_HEIGHT)&& h_count >= 535 && h_count < 637) begin
						  // Calculate row and column within the glyph
						  // row_index = (v_count - START_Y) % CHAR_HEIGHT;
						  // char_column = (h_count - START_X) / (CHAR_WIDTH); //CHAR_WIDTH;
						  
						 //   // Convert current_score to individual digits
						 // thousands = current_score / 1000; 
						 // hundreds = current_score  / 100;       // Extract hundreds place
						 // tens = (current_score / 10) % 10;    // Extract tens place
						 // units = current_score % 10;          // Extract units place
					
						 // Map digits to glyphs
						 case (char_column)
							  0: char_code = thousands;  //+ 5'd0;  // Third digit (units place)
							  1: char_code = hundreds;  //+ 5'd0; // First digit (hundreds place)
							  2: char_code = tens;  //+ 5'd0;    // Second digit (tens place)
							  3: char_code = units;  //+ 5'd0;  // Third digit (units place)
							  default: char_code = 5'd19;   // Blank space
						 endcase
										 
						  // Determine pixel color based on glyph ROM
						  if (glyph_pixels[CHAR_WIDTH - 1 - ((h_count - START_X) % CHAR_WIDTH)]) begin
								rgb = 3'b111; // White for glyph pixels
						  end
					 end
					 else if (v_count >= START_Y + (3* CHAR_HEIGHT) && v_count < (START_Y + (3* CHAR_HEIGHT)) + 10
					&& h_count < 637) begin
						
							rgb = 3'b000; 
					 
					 end
					else begin
							case ((h_count + v_count) % 3)
								0: rgb = 3'b000; 
								1: rgb = 3'b100; // Green
								2: rgb = 3'b001; // Blue
								default: rgb = 3'b000; 
								endcase
					end 

				end

		  
	
		  
		  
		  
		 
		  
		  
        // LANE ONE
        if (h_count >= 108 && h_count < 212) begin
			
				for (i = 0; i < 8; i = i + 2) begin // first four blocks
					if (v_count >= blocks_reg[i][9:0] && v_count < blocks_reg[i+1][9:0]) begin
              rgb = blocks_reg[i][15:13];
						 // rgb = 3'b111; 
					end
				end
        end

		  // LANE TWO
        if (h_count >= 214 && h_count < 318) begin
			
				for (j = 8; j < 16; j = j + 2) begin // second four blocks 
					if (v_count >= blocks_reg[j][9:0] && v_count < blocks_reg[j+1][9:0]) begin
						rgb = blocks_reg[j][15:13]; 
						 // rgb = 3'b111;
					end
				end 
        end
        
		  // LANE THREE
        if (h_count >= 320 && h_count < 424) begin
			
				for (k = 16; k < 24; k = k + 2) begin // third four blocks 16 17, 18 19, 19 20, 20 21
					if (v_count >= blocks_reg[k][9:0] && v_count < blocks_reg[k+1][9:0]) begin
						rgb = blocks_reg[k][15:13]; 
						 // rgb = 3'b111;
					end
				end 
        end
        
		  // LANE FOUR 
        if (h_count >= 426 && h_count < 528) begin

				for (t = 24; t < 32; t = t + 2) begin // fourth four blocks 
					if (v_count >= blocks_reg[t][9:0] && v_count < blocks_reg[t+1][9:0]) begin
						rgb = blocks_reg[t][15:13]; 
						 // rgb = 3'b111;
					end
				end 
        end
    end


						   // Convert current_score to individual digits
     assign thousands = current_score / 1000; 
     assign hundreds = current_score  / 100;       // Extract hundreds place
     assign tens = (current_score / 10) % 10;    // Extract tens place
     assign units = current_score % 10;          // Extract units place
     assign row_index = (v_count - START_Y) % CHAR_HEIGHT;
		 assign char_column = (h_count - START_X) / (CHAR_WIDTH); //CHAR_WIDTH;

endmodule



	



	
		
		
	module glyph_rom (
    input clk,
    input [4:0] char,      // Character code (0-9) and 9 letters 
    input [3:0] row,       // Row index (0-6)
    output [11:0] pixels // Pixel data for the row (5 bits wide)
	);
  // (* ramstyle = "logic" *) reg [11:0] lut0 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut1 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut2 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut3 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut4 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut5 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut6 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut7 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut8 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut9 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut10 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut11 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut12 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut13 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut14 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut15 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut16 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut17 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut18 [15:0];
  // (* ramstyle = "logic" *) reg [11:0] lut19 [15:0];

  wire [11:0] lut_data [19:0];

    // wire [11:0] lut0_data;
    // reg [11:0] lut1_data, lut2_data, lut3_data, lut4_data, lut5_data, lut6_data;
    // reg [11:0] lut7_data, lut8_data, lut9_data, lut10_data, lut11_data, lut12_data;
    // reg [11:0] lut13_data, lut14_data, lut15_data, lut16_data, lut17_data, lut18_data;
    // reg [11:0] lut19_data;

    assign pixels = lut_data[char];


    // always @(*) begin 
    //   case(char) 
    //     5'd0: pixels = lut0[row];
    //     5'd1: pixels = lut1[row];
    //     5'd2: pixels = lut2[row];
    //     5'd3: pixels = lut3[row];
    //     5'd4: pixels = lut4[row];
    //     5'd5: pixels = lut5[row];
    //     5'd6: pixels = lut6[row];
    //     5'd7: pixels = lut7[row];
    //     5'd8: pixels = lut8[row];
    //     5'd9: pixels = lut9[row];
    //     5'd10: pixels = lut10[row];
    //     5'd11: pixels = lut11[row];
    //     5'd12: pixels = lut12[row];
    //     5'd13: pixels = lut13[row];
    //     5'd14: pixels = lut14[row];
    //     5'd15: pixels = lut15[row];
    //     5'd16: pixels = lut16[row];
    //     5'd17: pixels = lut17[row];
    //     5'd18: pixels = lut18[row];
    //     5'd19: pixels = lut19[row];
    //     default: pixels = lut0[row];
    //   endcase
    // end

    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_0.mif") mlab0 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[0])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_1.mif") mlab1 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[1])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_2.mif") mlab2 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[2])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_3.mif") mlab3 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[3])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_4.mif") mlab4 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[4])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_5.mif") mlab5 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[5])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_6.mif") mlab6 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[6])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_7.mif") mlab7 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[7])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_8.mif") mlab8 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[8])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_9.mif") mlab9 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[9])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_10.mif") mlab10 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[10])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_11.mif") mlab11 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[11])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_12.mif") mlab12 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[12])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_13.mif") mlab13 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[13])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_14.mif") mlab14 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[14])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_15.mif") mlab15 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[15])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_16.mif") mlab16 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[16])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_17.mif") mlab17 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[17])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_18.mif") mlab18 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[18])
    );
    MLAB_rom #(12, 5, "/home/aidan/Classes/Fall24/ECE3710/TeamProject/repo/mem_files/lut_files/mlab_19.mif") mlab19 (
      .clk(clk), 
      .a(row), 
      .q(lut_data[19])
    );
    
    // lut 0
    // initial begin 
    //   lut0[0] = 12'b000000000000;
    //   lut0[1] = 12'b001111111100;
    //   lut0[2] = 12'b011111111110;
    //   lut0[3] = 12'b011100001110;
    //   lut0[4] = 12'b011100001110;
    //   lut0[5] = 12'b011100001110;
    //   lut0[6] = 12'b011100001110;
    //   lut0[7] = 12'b011100001110;
    //   lut0[8] = 12'b011100001110;
    //   lut0[9] = 12'b011111111110;
    //   lut0[10] = 12'b001111111100;
    //   lut0[11] = 12'b000000000000;
    // end


    // // always @(*) begin
    // // 	case (char) 
    //   always @(*) begin
    // // 5'd0: 
    //      case (row)
    //   4'd0: lut0_data = 12'b000000000000;
    //   4'd1: lut0_data = 12'b001111111100;
    //   4'd2: lut0_data = 12'b011111111110;
    //   4'd3: lut0_data = 12'b011100001110;
    //   4'd4: lut0_data = 12'b011100001110;
    //   4'd5: lut0_data = 12'b011100001110;
    //   4'd6: lut0_data = 12'b011100001110;
    //   4'd7: lut0_data = 12'b011100001110;
    //   4'd8: lut0_data = 12'b011100001110;
    //   4'd9: lut0_data = 12'b011111111110;
    //   4'd10: lut0_data = 12'b001111111100;
    //   4'd11: lut0_data = 12'b000000000000;
    //   default: lut0_data = 12'b000000000000;
    // endcase
    //  end

    // lut 1
    // initial begin 
    //   lut1[0] =   12'b000000000000;
    //   lut1[1] =   12'b000001110000;
    //   lut1[2] =   12'b000011110000;
    //   lut1[3] =   12'b000111110000;
    //   lut1[4] =   12'b000001110000;
    //   lut1[5] =   12'b000001110000;
    //   lut1[6] =   12'b000001110000;
    //   lut1[7] =   12'b000001110000;
    //   lut1[8] =   12'b000001110000;
    //   lut1[9] =   12'b011111111110;
    //   lut1[10] =  12'b011111111110;
    //   lut1[11] =  12'b000000000000;
    // end

			 //
			 //  always @(*) begin
			 // // 5'd1: 
			 //      case (row)
			 //   4'd0: lut1_data = 12'b000000000000;
			 //   4'd1: lut1_data = 12'b000001110000;
			 //   4'd2: lut1_data = 12'b000011110000;
			 //   4'd3: lut1_data = 12'b000111110000;
			 //   4'd4: lut1_data = 12'b000001110000;
			 //   4'd5: lut1_data = 12'b000001110000;
			 //   4'd6: lut1_data = 12'b000001110000;
			 //   4'd7: lut1_data = 12'b000001110000;
			 //   4'd8: lut1_data = 12'b000001110000;
			 //   4'd9: lut1_data = 12'b011111111110;
			 //   4'd10: lut1_data = 12'b011111111110;
			 //   4'd11: lut1_data = 12'b000000000000;
			 //   default: lut1_data = 12'b000000000000;
			 // endcase
			 //  end
			 // 5'd2: 
       
       // lut 2
       // initial begin 
       //   lut2[0] =  12'b000000000000;
       //   lut2[1] =  12'b001111111100;
       //   lut2[2] =  12'b011111111110;
       //   lut2[3] =  12'b011100001110;
       //   lut2[4] =  12'b000000011110;
       //   lut2[5] =  12'b000000111100;
       //   lut2[6] =  12'b000011111000;
       //   lut2[7] =  12'b000111110000;
       //   lut2[8] =  12'b011111000000;
       //   lut2[9] =  12'b011111111110;
       //   lut2[10] = 12'b011111111110;
       //   lut2[11] = 12'b000000000000;
       // end
       //
			 //    always @(*) begin  
			 //    case (row)
			 //   4'd0: lut2_data = 12'b000000000000;
			 //   4'd1: lut2_data = 12'b001111111100;
			 //   4'd2: lut2_data = 12'b011111111110;
			 //   4'd3: lut2_data = 12'b011100001110;
			 //   4'd4: lut2_data = 12'b000000011110;
			 //   4'd5: lut2_data = 12'b000000111100;
			 //   4'd6: lut2_data = 12'b000011111000;
			 //   4'd7: lut2_data = 12'b000111110000;
			 //   4'd8: lut2_data = 12'b011111000000;
			 //   4'd9: lut2_data = 12'b011111111110;
			 //   4'd10: lut2_data = 12'b011111111110;
			 //   4'd11: lut2_data = 12'b000000000000;
			 //   default: lut2_data = 12'b000000000000;
			 // endcase
			 //  end
       
       // lut 3 
       // initial begin 
       //  lut3[0] =   12'b000000000000;
       //  lut3[1] =   12'b001111111100;
       //  lut3[2] =   12'b011111111110;
       //  lut3[3] =   12'b011100001110;
       //  lut3[4] =   12'b000000011110;
       //  lut3[5] =   12'b001111111100;
       //  lut3[6] =   12'b001111111100;
       //  lut3[7] =   12'b000000011110;
       //  lut3[8] =   12'b011100001110;
       //  lut3[9] =   12'b011111111110;
       //  lut3[10] =  12'b001111111100;
       //  lut3[11] =  12'b000000000000;
       // end

			 // // 5'd3: 
			 //    always @(*) begin 
			 //    case (row)
			 //   4'd0: lut3_data = 12'b000000000000;
			 //   4'd1: lut3_data = 12'b001111111100;
			 //   4'd2: lut3_data = 12'b011111111110;
			 //   4'd3: lut3_data = 12'b011100001110;
			 //   4'd4: lut3_data = 12'b000000011110;
			 //   4'd5: lut3_data = 12'b001111111100;
			 //   4'd6: lut3_data = 12'b001111111100;
			 //   4'd7: lut3_data = 12'b000000011110;
			 //   4'd8: lut3_data = 12'b011100001110;
			 //   4'd9: lut3_data = 12'b011111111110;
			 //   4'd10: lut3_data = 12'b001111111100;
			 //   4'd11: lut3_data = 12'b000000000000;
			 //   default: lut3_data = 12'b000000000000;
			 // endcase
			 //  end

        // lut 4 
        // initial begin 
        //   lut4[0] =  12'b000000000000;
        //   lut4[1] =  12'b000000011100;
        //   lut4[2] =  12'b000000111100;
        //   lut4[3] =  12'b000001111100;
        //   lut4[4] =  12'b000011011100;
        //   lut4[5] =  12'b000110011100;
        //   lut4[6] =  12'b001100011100;
        //   lut4[7] =  12'b011111111110;
        //   lut4[8] =  12'b011111111110;
        //   lut4[9] =  12'b000000011100;
        //   lut4[10] = 12'b000000011100;
        //   lut4[11] = 12'b000000000000;
        // end

			 // // 5'd4: 
			 //    always @(*) begin  
			 //      case (row)
			 //   4'd0: lut4_data = 12'b000000000000;
			 //   4'd1: lut4_data = 12'b000000011100;
			 //   4'd2: lut4_data = 12'b000000111100;
			 //   4'd3: lut4_data = 12'b000001111100;
			 //   4'd4: lut4_data = 12'b000011011100;
			 //   4'd5: lut4_data = 12'b000110011100;
			 //   4'd6: lut4_data = 12'b001100011100;
			 //   4'd7: lut4_data = 12'b011111111110;
			 //   4'd8: lut4_data = 12'b011111111110;
			 //   4'd9: lut4_data = 12'b000000011100;
			 //   4'd10: lut4_data = 12'b000000011100;
			 //   4'd11: lut4_data = 12'b000000000000;
			 //   default: lut4_data = 12'b000000000000;
			 // endcase
			 //  end

        // lut 5 
        // initial begin 
        //   lut5[0] =  12'b000000000000;
        //   lut5[1] =  12'b011111111110;
        //   lut5[2] =  12'b011111111110;
        //   lut5[3] =  12'b011100000000;
        //   lut5[4] =  12'b011111111100;
        //   lut5[5] =  12'b011111111110;
        //   lut5[6] =  12'b000000001110;
        //   lut5[7] =  12'b000000001110;
        //   lut5[8] =  12'b011100001110;
        //   lut5[9] =  12'b011111111110;
        //   lut5[10] = 12'b001111111100;
        //   lut5[11] = 12'b000000000000;
        // end

			 // // 5'd5: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut5_data = 12'b000000000000;
			 //   4'd1: lut5_data = 12'b011111111110;
			 //   4'd2: lut5_data = 12'b011111111110;
			 //   4'd3: lut5_data = 12'b011100000000;
			 //   4'd4: lut5_data = 12'b011111111100;
			 //   4'd5: lut5_data = 12'b011111111110;
			 //   4'd6: lut5_data = 12'b000000001110;
			 //   4'd7: lut5_data = 12'b000000001110;
			 //   4'd8: lut5_data = 12'b011100001110;
			 //   4'd9: lut5_data = 12'b011111111110;
			 //   4'd10: lut5_data = 12'b001111111100;
			 //   4'd11: lut5_data = 12'b000000000000;
			 //   default: lut5_data = 12'b000000000000;
			 // endcase
			 //  end
       
        // lut 6 
        // initial begin
        //   lut6[0] =  12'b000000000000;
        //   lut6[1] =  12'b001111111100;
        //   lut6[2] =  12'b011111111000;
        //   lut6[3] =  12'b011100000000;
        //   lut6[4] =  12'b011111111100;
        //   lut6[5] =  12'b011111111110;
        //   lut6[6] =  12'b011100001110;
        //   lut6[7] =  12'b011100001110;
        //   lut6[8] =  12'b011100001110;
        //   lut6[9] =  12'b011111111110;
        //   lut6[10] = 12'b001111111100;
        //   lut6[11] = 12'b000000000000;
        // end


			 // // 5'd6: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut6_data = 12'b000000000000;
			 //   4'd1: lut6_data = 12'b001111111100;
			 //   4'd2: lut6_data = 12'b011111111000;
			 //   4'd3: lut6_data = 12'b011100000000;
			 //   4'd4: lut6_data = 12'b011111111100;
			 //   4'd5: lut6_data = 12'b011111111110;
			 //   4'd6: lut6_data = 12'b011100001110;
			 //   4'd7: lut6_data = 12'b011100001110;
			 //   4'd8: lut6_data = 12'b011100001110;
			 //   4'd9: lut6_data = 12'b011111111110;
			 //   4'd10: lut6_data = 12'b001111111100;
			 //   4'd11: lut6_data = 12'b000000000000;
			 //   default: lut6_data = 12'b000000000000;
			 // endcase
			 //  end
       

       // lut 7
				  //  initial begin
				  // lut7[0] =  12'b000000000000;
				  // lut7[1] =  12'b011111111110;
				  // lut7[2] =  12'b011111111110;
				  // lut7[3] =  12'b011100001110;
				  // lut7[4] =  12'b000000011100;
				  // lut7[5] =  12'b000000111000;
				  // lut7[6] =  12'b000001110000;
				  // lut7[7] =  12'b000011100000;
				  // lut7[8] =  12'b000111000000;
				  // lut7[9] =  12'b000111000000;
				  // lut7[10] = 12'b000111000000;
				  // lut7[11] = 12'b000000000000;
				  //  end
			 // // 5'd7: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut7_data = 12'b000000000000;
			 //   4'd1: lut7_data = 12'b011111111110;
			 //   4'd2: lut7_data = 12'b011111111110;
			 //   4'd3: lut7_data = 12'b011100001110;
			 //   4'd4: lut7_data = 12'b000000011100;
			 //   4'd5: lut7_data = 12'b000000111000;
			 //   4'd6: lut7_data = 12'b000001110000;
			 //   4'd7: lut7_data = 12'b000011100000;
			 //   4'd8: lut7_data = 12'b000111000000;
			 //   4'd9: lut7_data = 12'b000111000000;
			 //   4'd10: lut7_data = 12'b000111000000;
			 //   4'd11: lut7_data = 12'b000000000000;
			 //   default: lut7_data = 12'b000000000000;
			 // endcase
			 //  end

       // lut 8
				  //  initial begin
				  // lut8[0] =  12'b000000000000;
				  // lut8[1] =  12'b001111111100;
				  // lut8[2] =  12'b011111111110;
				  // lut8[3] =  12'b011100001110;
				  // lut8[4] =  12'b011111111110;
				  // lut8[5] =  12'b001111111100;
				  // lut8[6] =  12'b011111111110;
				  // lut8[7] =  12'b011100001110;
				  // lut8[8] =  12'b011100001110;
				  // lut8[9] =  12'b011111111110;
				  // lut8[10] = 12'b001111111100;
				  // lut8[11] = 12'b000000000000;
				  //  end
			 // // 5'd8: 
			 //    always @(*) begin 
			 //      case (row)
			 //   4'd0: lut8_data = 12'b000000000000;
			 //   4'd1: lut8_data = 12'b001111111100;
			 //   4'd2: lut8_data = 12'b011111111110;
			 //   4'd3: lut8_data = 12'b011100001110;
			 //   4'd4: lut8_data = 12'b011111111110;
			 //   4'd5: lut8_data = 12'b001111111100;
			 //   4'd6: lut8_data = 12'b011111111110;
			 //   4'd7: lut8_data = 12'b011100001110;
			 //   4'd8: lut8_data = 12'b011100001110;
			 //   4'd9: lut8_data = 12'b011111111110;
			 //   4'd10: lut8_data = 12'b001111111100;
			 //   4'd11: lut8_data = 12'b000000000000;
			 //   default: lut8_data = 12'b000000000000;
			 // endcase
       //
       // lut 9
				  //  initial begin
				  // lut9[0] =  12'b000000000000;
				  // lut9[1] =  12'b001111111100;
				  // lut9[2] =  12'b011111111110;
				  // lut9[3] =  12'b011100001110;
				  // lut9[4] =  12'b011100001110;
				  // lut9[5] =  12'b011111111110;
				  // lut9[6] =  12'b001111111110;
				  // lut9[7] =  12'b000000001110;
				  // lut9[8] =  12'b011100001110;
				  // lut9[9] =  12'b011111111110;
				  // lut9[10] = 12'b001111111100;
				  // lut9[11] = 12'b000000000000;
				  //  end
			 //  always @(*) begin
			 //  case (row)
			 //   4'd0: lut9_data = 12'b000000000000;
			 //   4'd1: lut9_data = 12'b001111111100;
			 //   4'd2: lut9_data = 12'b011111111110;
			 //   4'd3: lut9_data = 12'b011100001110;
			 //   4'd4: lut9_data = 12'b011100001110;
			 //   4'd5: lut9_data = 12'b011111111110;
			 //   4'd6: lut9_data = 12'b001111111110;
			 //   4'd7: lut9_data = 12'b000000001110;
			 //   4'd8: lut9_data = 12'b011100001110;
			 //   4'd9: lut9_data = 12'b011111111110;
			 //   4'd10: lut9_data = 12'b001111111100;
			 //   4'd11: lut9_data = 12'b000000000000;
			 //   default: lut9_data = 12'b000000000000;
			 // endcase
			 //  end
			 
        // lut 10
				  //  initial begin
				  // lut10[0] =  12'b000000000000;
				  // lut10[1] =  12'b011111111100;
				  // lut10[2] =  12'b011111111110;
				  // lut10[3] =  12'b011100001110;
				  // lut10[4] =  12'b011100001110;
				  // lut10[5] =  12'b011111111100;
				  // lut10[6] =  12'b011111111000;
				  // lut10[7] =  12'b011101110000;
				  // lut10[8] =  12'b011100111000;
				  // lut10[9] =  12'b011100011110;
				  // lut10[10] = 12'b011100001110;
				  // lut10[11] = 12'b000000000000;
				  //  end

			 //   always @(*) begin
			 //      case (row)
			 //   4'd0: lut10_data = 12'b000000000000;
			 //   4'd1: lut10_data = 12'b011111111100;
			 //   4'd2: lut10_data = 12'b011111111110;
			 //   4'd3: lut10_data = 12'b011100001110;
			 //   4'd4: lut10_data = 12'b011100001110;
			 //   4'd5: lut10_data = 12'b011111111100;
			 //   4'd6: lut10_data = 12'b011111111000;
			 //   4'd7: lut10_data = 12'b011101110000;
			 //   4'd8: lut10_data = 12'b011100111000;
			 //   4'd9: lut10_data = 12'b011100011110;
			 //   4'd10: lut10_data = 12'b011100001110;
			 //   4'd11: lut10_data = 12'b000000000000;
			 //   default: lut10_data = 12'b000000000000;
			 // endcase
			 //  end
		
        // lut 11
				  //  initial begin
				  // lut11[0] =  12'b000000000000;
				  // lut11[1] =  12'b001100001100;
				  // lut11[2] =  12'b001100001100;
				  // lut11[3] =  12'b001100001100;
				  // lut11[4] =  12'b001111111100;
				  // lut11[5] =  12'b001111111100;
				  // lut11[6] =  12'b001100001100;
				  // lut11[7] =  12'b001100001100;
				  // lut11[8] =  12'b001100001100;
				  // lut11[9] =  12'b001100001100;
				  // lut11[10] = 12'b001100001100;
				  // lut11[11] = 12'b000000000000;
				  //  end
			 // // H
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut11_data = 12'b000000000000;
			 //   4'd1: lut11_data = 12'b001100001100;
			 //   4'd2: lut11_data = 12'b001100001100;
			 //   4'd3: lut11_data = 12'b001100001100;
			 //   4'd4: lut11_data = 12'b001111111100;
			 //   4'd5: lut11_data = 12'b001111111100;
			 //   4'd6: lut11_data = 12'b001100001100;
			 //   4'd7: lut11_data = 12'b001100001100;
			 //   4'd8: lut11_data = 12'b001100001100;
			 //   4'd9: lut11_data = 12'b001100001100;
			 //   4'd10: lut11_data = 12'b001100001100;
			 //   4'd11: lut11_data = 12'b000000000000;
			 //   default: lut11_data = 12'b000000000000;
			 // endcase
			 //  end

       // lut 12
				  //  initial begin
				  // lut12[0] =  12'b000000000000;
				  // lut12[1] =  12'b011100001110;
				  // lut12[2] =  12'b011100001110;
				  // lut12[3] =  12'b011100001110;
				  // lut12[4] =  12'b001110011100;
				  // lut12[5] =  12'b001111111100;
				  // lut12[6] =  12'b000011110000;
				  // lut12[7] =  12'b000011110000;
				  // lut12[8] =  12'b000011110000;
				  // lut12[9] =  12'b000011110000;
				  // lut12[10] = 12'b000011110000;
				  // lut12[11] = 12'b000000000000;
				  //  end
     
		  // always @(*) begin
		  //      case (row)
		  //   4'd0: lut12_data = 12'b000000000000;
		  //   4'd1: lut12_data = 12'b011100001110;
		  //   4'd2: lut12_data = 12'b011100001110;
		  //   4'd3: lut12_data = 12'b011100001110;
		  //   4'd4: lut12_data = 12'b001110011100;
		  //   4'd5: lut12_data = 12'b001111111100;
		  //   4'd6: lut12_data = 12'b000011110000;
		  //   4'd7: lut12_data = 12'b000011110000;
		  //   4'd8: lut12_data = 12'b000011110000;
		  //   4'd9: lut12_data = 12'b000011110000;
		  //   4'd10: lut12_data = 12'b000011110000;
		  //   4'd11: lut12_data = 12'b000000000000;
		  //   default: lut12_data = 12'b000000000000;
		  // endcase
		  //  end
		
			 // T
       // lut 13
				  //  initial begin
				  // lut13[0] =  12'b000000000000;
				  // lut13[1] =  12'b011111111110;
				  // lut13[2] =  12'b011111111110;
				  // lut13[3] =  12'b000011110000;
				  // lut13[4] =  12'b000011110000;
				  // lut13[5] =  12'b000011110000;
				  // lut13[6] =  12'b000011110000;
				  // lut13[7] =  12'b000011110000;
				  // lut13[8] =  12'b000011110000;
				  // lut13[9] =  12'b000011110000;
				  // lut13[10] = 12'b000001100000;
				  // lut13[11] = 12'b000000000000;
				  //  end
			 // 5'd13: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut13_data = 12'b000000000000;
			 //   4'd1: lut13_data = 12'b011111111110;
			 //   4'd2: lut13_data = 12'b011111111110;
			 //   4'd3: lut13_data = 12'b000011110000;
			 //   4'd4: lut13_data = 12'b000011110000;
			 //   4'd5: lut13_data = 12'b000011110000;
			 //   4'd6: lut13_data = 12'b000011110000;
			 //   4'd7: lut13_data = 12'b000011110000;
			 //   4'd8: lut13_data = 12'b000011110000;
			 //   4'd9: lut13_data = 12'b000011110000;
			 //   4'd10: lut13_data = 12'b000001100000;
			 //   4'd11: lut13_data = 12'b000000000000;
			 //   default: lut13_data = 12'b000000000000;
			 // endcase
			 //  end
       // lut 14
     //   initial begin
     //  lut14[0] =  12'b000000000000;
     //  lut14[1] =  12'b011100001110;
     //  lut14[2] =  12'b011110011110;
     //  lut14[3] =  12'b011111111110;
     //  lut14[4] =  12'b011111111110;
     //  lut14[5] =  12'b011101101110;
     //  lut14[6] =  12'b011100001110;
     //  lut14[7] =  12'b011100001110;
     //  lut14[8] =  12'b011100001110;
     //  lut14[9] =  12'b011100001110;
     //  lut14[10] = 12'b011100001110;
     //  lut14[11] = 12'b000000000000;
     // end
			 // 5'd14: 
			 // M
			 //   always @(*) begin
			 //      case (row)
			 //   4'd0: lut14_data = 12'b000000000000;
			 //   4'd1: lut14_data = 12'b011100001110;
			 //   4'd2: lut14_data = 12'b011110011110;
			 //   4'd3: lut14_data = 12'b011111111110;
			 //   4'd4: lut14_data = 12'b011111111110;
			 //   4'd5: lut14_data = 12'b011101101110;
			 //   4'd6: lut14_data = 12'b011100001110;
			 //   4'd7: lut14_data = 12'b011100001110;
			 //   4'd8: lut14_data = 12'b011100001110;
			 //   4'd9: lut14_data = 12'b011100001110;
			 //   4'd10: lut14_data = 12'b011100001110;
			 //   4'd11: lut14_data = 12'b000000000000;
			 //   default: lut14_data = 12'b000000000000;
			 // endcase
			 //  end
       // lut 15
     //   initial begin
     //  lut15[0] =  12'b000000000000;
     //  lut15[1] =  12'b001111111100;
     //  lut15[2] =  12'b011111111110;
     //  lut15[3] =  12'b011100001110;
     //  lut15[4] =  12'b011100000000;
     //  lut15[5] =  12'b001111111000;
     //  lut15[6] =  12'b000111111100;
     //  lut15[7] =  12'b000000011100;
     //  lut15[8] =  12'b011100011100;
     //  lut15[9] =  12'b011111111110;
     //  lut15[10] = 12'b001111111100;
     //  lut15[11] = 12'b000000000000;
     // end
		
			 // S
			 // 5'd15: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut15_data = 12'b000000000000;
			 //   4'd1: lut15_data = 12'b001111111100;
			 //   4'd2: lut15_data = 12'b011111111110;
			 //   4'd3: lut15_data = 12'b011100001110;
			 //   4'd4: lut15_data = 12'b011100000000;
			 //   4'd5: lut15_data = 12'b001111111000;
			 //   4'd6: lut15_data = 12'b000111111100;
			 //   4'd7: lut15_data = 12'b000000011100;
			 //   4'd8: lut15_data = 12'b011100011100;
			 //   4'd9: lut15_data = 12'b011111111110;
			 //   4'd10: lut15_data = 12'b001111111100;
			 //   4'd11: lut15_data = 12'b000000000000;
			 //   default: lut15_data = 12'b000000000000;
			 // endcase
			 //  end

       // lut 16
     //   initial begin
     //  lut16[0] =  12'b000000000000;
     //  lut16[1] =  12'b001111111100;
     //  lut16[2] =  12'b011111111110;
     //  lut16[3] =  12'b011100001110;
     //  lut16[4] =  12'b011100000000;
     //  lut16[5] =  12'b011100000000;
     //  lut16[6] =  12'b011100000000;
     //  lut16[7] =  12'b011100000000;
     //  lut16[8] =  12'b011100001110;
     //  lut16[9] =  12'b011111111110;
     //  lut16[10] = 12'b001111111100;
     //  lut16[11] = 12'b000000000000;
     // end
		
			 // C
			 // 5'd16: 
			 //   always @(*) begin
			 //      case (row)
			 //   4'd0: lut16_data = 12'b000000000000;
			 //   4'd1: lut16_data = 12'b001111111100;
			 //   4'd2: lut16_data = 12'b011111111110;
			 //   4'd3: lut16_data = 12'b011100001110;
			 //   4'd4: lut16_data = 12'b011100000000;
			 //   4'd5: lut16_data = 12'b011100000000;
			 //   4'd6: lut16_data = 12'b011100000000;
			 //   4'd7: lut16_data = 12'b011100000000;
			 //   4'd8: lut16_data = 12'b011100001110;
			 //   4'd9: lut16_data = 12'b011111111110;
			 //   4'd10: lut16_data = 12'b001111111100;
			 //   4'd11: lut16_data = 12'b000000000000;
			 //   default: lut16_data = 12'b000000000000;
			 // endcase
			 //  end

       // lut 17
     //   initial begin
     //  lut17[0] =  12'b000000000000;
     //  lut17[1] =  12'b001111111100;
     //  lut17[2] =  12'b011111111110;
     //  lut17[3] =  12'b011100001110;
     //  lut17[4] =  12'b011100001110;
     //  lut17[5] =  12'b011100001110;
     //  lut17[6] =  12'b011100001110;
     //  lut17[7] =  12'b011100001110;
     //  lut17[8] =  12'b011100001110;
     //  lut17[9] =  12'b011111111110;
     //  lut17[10] = 12'b001111111100;
     //  lut17[11] = 12'b000000000000;
     // end
		
			 // O
			 // 5'd17: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut17_data = 12'b000000000000;
			 //   4'd1: lut17_data = 12'b001111111100;
			 //   4'd2: lut17_data = 12'b011111111110;
			 //   4'd3: lut17_data = 12'b011100001110;
			 //   4'd4: lut17_data = 12'b011100001110;
			 //   4'd5: lut17_data = 12'b011100001110;
			 //   4'd6: lut17_data = 12'b011100001110;
			 //   4'd7: lut17_data = 12'b011100001110;
			 //   4'd8: lut17_data = 12'b011100001110;
			 //   4'd9: lut17_data = 12'b011111111110;
			 //   4'd10: lut17_data = 12'b001111111100;
			 //   4'd11: lut17_data = 12'b000000000000;
			 //   default: lut17_data = 12'b000000000000;
			 // endcase
			 //  end

       // lut 18
				  //  initial begin
				  // lut18[0] =  12'b000000000000;
				  // lut18[1] =  12'b001111111110;
				  // lut18[2] =  12'b011111111110;
				  // lut18[3] =  12'b011100000000;
				  // lut18[4] =  12'b011100000000;
				  // lut18[5] =  12'b011111111100;
				  // lut18[6] =  12'b011111111100;
				  // lut18[7] =  12'b011100000000;
				  // lut18[8] =  12'b011100000000;
				  // lut18[9] =  12'b011111111110;
				  // lut18[10] = 12'b001111111110;
				  // lut18[11] = 12'b000000000000;
				  //   end
		
			 // E
			 // 5'd18: 
				  //  always @(*) begin
				  //    case (row)
				  // 4'd0: lut18_data = 12'b000000000000;
				  // 4'd1: lut18_data = 12'b001111111110;
				  // 4'd2: lut18_data = 12'b011111111110;
				  // 4'd3: lut18_data = 12'b011100000000;
				  // 4'd4: lut18_data = 12'b011100000000;
				  // 4'd5: lut18_data = 12'b011111111100;
				  // 4'd6: lut18_data = 12'b011111111100;
				  // 4'd7: lut18_data = 12'b011100000000;
				  // 4'd8: lut18_data = 12'b011100000000;
				  // 4'd9: lut18_data = 12'b011111111110;
				  // 4'd10: lut18_data = 12'b001111111110;
				  // 4'd11: lut18_data = 12'b000000000000;
				  // default: lut18_data = 12'b000000000000;
				  // endcase 
				  //   end
        // lut 19
     //    initial begin
     //  lut19[0] =  12'b000000000000;
     //  lut19[1] =  12'b000000000000;
     //  lut19[2] =  12'b000000000000;
     //  lut19[3] =  12'b000000000000;
     //  lut19[4] =  12'b000000000000;
     //  lut19[5] =  12'b000000000000;
     //  lut19[6] =  12'b000000000000;
     //  lut19[7] =  12'b000000000000;
     //  lut19[8] =  12'b000000000000;
     //  lut19[9] =  12'b000000000000;
     //  lut19[10] = 12'b000000000000;
     //  lut19[11] = 12'b000000000000;
     // end
				  
			 // E
			 // 5'd19: 
			 //    always @(*) begin
			 //      case (row)
			 //   4'd0: lut19_data = 12'b000000000000;
			 //   4'd1: lut19_data = 12'b000000000000;
			 //   4'd2: lut19_data = 12'b000000000000;
			 //   4'd3: lut19_data = 12'b000000000000;
			 //   4'd4: lut19_data = 12'b000000000000;
			 //   4'd5: lut19_data = 12'b000000000000;
			 //   4'd6: lut19_data = 12'b000000000000;
			 //   4'd7: lut19_data = 12'b000000000000;
			 //   4'd8: lut19_data = 12'b000000000000;
			 //   4'd9: lut19_data = 12'b000000000000;
			 //   4'd10: lut19_data = 12'b000000000000;
			 //   4'd11: lut19_data = 12'b000000000000;
			 //   default: lut19_data = 12'b000000000000;
			 // endcase
			 //  end
			 //    default: pixels = 12'b000000000000;
			 // endcase
	
 
    // end
 endmodule








