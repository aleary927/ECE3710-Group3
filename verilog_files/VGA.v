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
    output [15:0] memory_address,    // Address to read from memory
    output memory_read_enable       // Enable signal for memory reads
);

    // Signals for VGA timing and synchronization
	 // END OF LANE AT 450
	 
	 parameter STARTING = 240; // Change depending <--
    wire hSync, vSync, bright;
    wire [9:0] hCount, vCount;
    wire En;
	
	wire [3:0] rgb; 

   // COLORS ARE STORED IN THE UPPER 4 BITS OF STARTING ADDRESS PER BLOCK 
    reg [4:0] counter;    /// 16 POSSIBLE BLOCKS, 4 PER LANE AT A TIME   
	 
    reg read_done;             

 
    assign memory_address = STARTING + counter; // Starting at address 240 plus counter
    assign memory_read_enable = (counter < 32) && !read_done;

 
    wire start_memory_reads = (vCount >= 0) && (hCount >= 0) && bright; 
	 
	 reg [15:0] memory_trans; 
	 
	 reg[15:0] test_mem [31:0]; 
	 
	 reg [4:0] count_tracker; 
	 
		
		
		wire [11:0] current_score; 
		
		// OPTIONAL TO LIGHT UP TILE, could assign this somehow
		wire [3:0] tile_hit = 4'b0; 
		
		
		
		// CHANGE HERE DEPENDING ON MEM ADDRESS OF SCORE. 
		assign current_score = 12'd523; 
//	 
//
//always @(posedge clk) begin
// 
//	 test_mem[0] <= 30;    // Block 1 Start
//    test_mem[1] <= 100;   // Block 1 End
//    test_mem[2] <= 150;   // Block 2 Start
//    test_mem[3] <= 200;   // Block 2 End
//    test_mem[4] <= 250;   // Block 3 Start
//    test_mem[5] <= 300;   // Block 3 End
//    test_mem[6] <= 320;   // Block 4 Start
//    test_mem[7] <= 350;   // Block 4 End
//
//    // Lane 2 Blocks
//    test_mem[8]  <= 30;   // Block 5 Start
//    test_mem[9]  <= 100;  // Block 5 End
//    test_mem[10] <= 150;  // Block 6 Start
//    test_mem[11] <= 200;  // Block 6 End
//    test_mem[12] <= 250;  // Block 7 Start
//    test_mem[13] <= 300;  // Block 7 End
//    test_mem[14] <= 320;  // Block 8 Start
//    test_mem[15] <= 350;  // Block 8 End
//
//    // Lane 3 Blocks
//    test_mem[16] <= 30;   // Block 9 Start
//    test_mem[17] <= 100;  // Block 9 End
//    test_mem[18] <= 150;  // Block 10 Start
//    test_mem[19] <= 200;  // Block 10 End
//    test_mem[20] <= 250;  // Block 11 Start
//    test_mem[21] <= 300;  // Block 11 End
//    test_mem[22] <= 320;  // Block 12 Start
//    test_mem[23] <= 350;  // Block 12 End
//
//    // Lane 4 Blocks
//    test_mem[24] <= 30;   // Block 13 Start
//    test_mem[25] <= 100;  // Block 13 End
//    test_mem[26] <= 150;  // Block 14 Start
//    test_mem[27] <= 200;  // Block 14 End
//    test_mem[28] <= 250;  // Block 15 Start
//    test_mem[29] <= 300;  // Block 15 End
//    test_mem[30] <= 320;  // Block 16 Start
//    test_mem[31] <= 350;  // Block 16 End
//end



	 always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        read_done <= 0;
    end else if (start_memory_reads && !read_done) begin // Start memory reads
        if (counter < 32) begin
            memory_trans <= memory_read_data; //test_mem[counter]; THIS MAKES 1ST LANE GO WHITE WHEN NOT EXPLICITELY ASSIGNED. 
				count_tracker <= counter; 
            counter <= counter + 1;
        end else begin
            counter <= 0;       // Reset counter when all updates are done
            read_done <= 1;     // Mark as done
        end
    end
	  else if (!start_memory_reads) begin
        read_done <= 0;         // Reset read_done when start_memory_reads is not active
		  counter <= 0; 
    end
end


    
    vgaControl vgaInst (
        .clk(clk),
        .clr(1'b1),
        .hSync(hSync),
        .vSync(vSync),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount),
        .En(En)
    );

    
	bitGen_Glyph glyph_inst (
		 .clk(clk),
		 .h_count(hCount),
		 .v_count(vCount),
		 .current_score(current_score), 
		 .tile_hit(tile_hit),
		 .memory_trans(memory_trans), 
		 .counter(count_tracker), 
		 .rgb(rgb)
	);


    // Assign VGA signals
    assign VGA_CLK = En;
    assign VGA_SYNC_N = 1'b0;
    assign VGA_BLANK_N = bright;
    assign VGA_HS = hSync;
    assign VGA_VS = vSync;
    assign VGA_RED = {8{rgb[2]}};
    assign VGA_GREEN = {8{rgb[1]}};
    assign VGA_BLUE = {8{rgb[0]}};

endmodule

	
	



	module bitGen_Glyph (
    input clk,                
    input [9:0] h_count,      // Current pixel x-coordinate
    input [9:0] v_count,      // Current pixel y-coordinate
	 input [11:0] current_score, 
	 input [3:0] tile_hit, 
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
	 
	 
	   parameter CHAR_WIDTH = 16;  // Width of a single character
		parameter CHAR_HEIGHT = 12; // Height of a single character
		parameter START_X = 537;    // Starting x-coordinate for "RHYTHM GAME"
		parameter START_Y = 48;     // Starting y-coordinate for "RHYTHM GAME"
		
		// Glyph ROM instantiation
		wire [11:0] glyph_pixels;
		reg [4:0] char_code;
		reg [3:0] row_index;
		glyph_rom glyph_instance(
			 .char(char_code),
			 .row(row_index),
			 .pixels(glyph_pixels)
		);
	

			  // Manual assignment of blocks_reg
    always @(*) begin
        blocks_reg[counter] = memory_trans;   

    end
	 

 
	 reg [3:0] thousands, hundreds, tens, units;

     
    always @(*) begin
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
					if(tile_hit[0]) rgb = 3'b111;  
					
					 else rgb = 3'b100;
				end
				// End of lane 2
				else if (h_count >= 214 && h_count < 318 && v_count >= 450) begin
					if(tile_hit[1]) rgb = 3'b111; 
					else  rgb = 3'b101;
				end
				// End of lane 3
				else if (h_count >= 320 && h_count < 424 && v_count >= 450) begin
					 if(tile_hit[2]) rgb = 3'b111;
					 else rgb = 3'b010;
				end
				// End of lane 4
				else if (h_count >= 426 && h_count < 528 && v_count >= 450) begin
					 if(tile_hit[3]) rgb = 3'b111;
					 else rgb = 3'b110;
				end

				 
				 
			 // Background right
				if (h_count >= 530) begin
					reg [3:0] char_column;
					 if(v_count >= 38 && v_count < START_Y && h_count < 637) begin 
							rgb = 3'b000; 
					 end
					 else if (v_count >= START_Y && v_count < START_Y + CHAR_HEIGHT && h_count >= 535 && h_count < 637) begin
						  // Calculate row and column within the glyph
						  row_index = (v_count - START_Y) % 12;//CHAR_HEIGHT;
						  char_column = (h_count - START_X) / (CHAR_WIDTH);//CHAR_WIDTH;
						  
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
						  row_index = (v_count - START_Y) % CHAR_HEIGHT;
						  char_column = (h_count - START_X) / (CHAR_WIDTH); //CHAR_WIDTH;
						  
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
						  row_index = (v_count - START_Y) % CHAR_HEIGHT;
						  char_column = (h_count - START_X) / (CHAR_WIDTH); //CHAR_WIDTH;
						  
						   // Convert current_score to individual digits
						 thousands = current_score / 1000; 
						 hundreds = current_score  / 100;       // Extract hundreds place
						 tens = (current_score / 10) % 10;    // Extract tens place
						 units = current_score % 10;          // Extract units place
					
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
					if (v_count >= blocks_reg[i] && v_count < blocks_reg[i+1]) begin
               /// rgb = blocks_reg[i][15:12];
						 rgb = 3'b111; 
					end
				end
        end

		  // LANE TWO
        if (h_count >= 214 && h_count < 318) begin
			
				for (j = 8; j < 16; j = j + 2) begin // second four blocks 
					if (v_count >= blocks_reg[j] && v_count < blocks_reg[j+1]) begin
						//rgb = blocks_reg[j][15:12]; 
						 rgb = 3'b111;
					end
				end 
        end
        
		  // LANE THREE
        if (h_count >= 320 && h_count < 424) begin
			
				for (k = 16; k < 24; k = k + 2) begin // third four blocks 16 17, 18 19, 19 20, 20 21
					if (v_count >= blocks_reg[k] && v_count < blocks_reg[k+1]) begin
						//rgb = blocks_reg[k][15:12]; 
						 rgb = 3'b111;
					end
				end 
        end
        
		  // LANE FOUR 
        if (h_count >= 426 && h_count < 528) begin

				for (t = 24; t < 32; t = t + 2) begin // fourth four blocks 
					if (v_count >= blocks_reg[t] && v_count < blocks_reg[t+1]) begin
						//rgb = blocks_reg[t][15:12]; 
						 rgb = 3'b111;
					end
				end 
        end
    end
endmodule



	



	
		
		
	module glyph_rom (
    input [4:0] char,      // Character code (0-9) and 9 letters 
    input [3:0] row,       // Row index (0-6)
    output reg [11:0] pixels // Pixel data for the row (5 bits wide)
	);
    always @(*) begin
    	case (char) 
			 5'd0: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011100001110;
				  4'd5: pixels = 12'b011100001110;
				  4'd6: pixels = 12'b011100001110;
				  4'd7: pixels = 12'b011100001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd1: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b000001110000;
				  4'd2: pixels = 12'b000011110000;
				  4'd3: pixels = 12'b000111110000;
				  4'd4: pixels = 12'b000001110000;
				  4'd5: pixels = 12'b000001110000;
				  4'd6: pixels = 12'b000001110000;
				  4'd7: pixels = 12'b000001110000;
				  4'd8: pixels = 12'b000001110000;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b011111111110;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd2: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b000000011110;
				  4'd5: pixels = 12'b000000111100;
				  4'd6: pixels = 12'b000011111000;
				  4'd7: pixels = 12'b000111110000;
				  4'd8: pixels = 12'b011111000000;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b011111111110;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd3: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b000000011110;
				  4'd5: pixels = 12'b001111111100;
				  4'd6: pixels = 12'b001111111100;
				  4'd7: pixels = 12'b000000011110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd4: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b000000011100;
				  4'd2: pixels = 12'b000000111100;
				  4'd3: pixels = 12'b000001111100;
				  4'd4: pixels = 12'b000011011100;
				  4'd5: pixels = 12'b000110011100;
				  4'd6: pixels = 12'b001100011100;
				  4'd7: pixels = 12'b011111111110;
				  4'd8: pixels = 12'b011111111110;
				  4'd9: pixels = 12'b000000011100;
				  4'd10: pixels = 12'b000000011100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd5: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b011111111110;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100000000;
				  4'd4: pixels = 12'b011111111100;
				  4'd5: pixels = 12'b011111111110;
				  4'd6: pixels = 12'b000000001110;
				  4'd7: pixels = 12'b000000001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd6: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111000;
				  4'd3: pixels = 12'b011100000000;
				  4'd4: pixels = 12'b011111111100;
				  4'd5: pixels = 12'b011111111110;
				  4'd6: pixels = 12'b011100001110;
				  4'd7: pixels = 12'b011100001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd7: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b011111111110;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b000000011100;
				  4'd5: pixels = 12'b000000111000;
				  4'd6: pixels = 12'b000001110000;
				  4'd7: pixels = 12'b000011100000;
				  4'd8: pixels = 12'b000111000000;
				  4'd9: pixels = 12'b000111000000;
				  4'd10: pixels = 12'b000111000000;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd8: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011111111110;
				  4'd5: pixels = 12'b001111111100;
				  4'd6: pixels = 12'b011111111110;
				  4'd7: pixels = 12'b011100001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 5'd9: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011100001110;
				  4'd5: pixels = 12'b011111111110;
				  4'd6: pixels = 12'b001111111110;
				  4'd7: pixels = 12'b000000001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 

			 // R
			 5'd10: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b011111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011100001110;
				  4'd5: pixels = 12'b011111111100;
				  4'd6: pixels = 12'b011111111000;
				  4'd7: pixels = 12'b011101110000;
				  4'd8: pixels = 12'b011100111000;
				  4'd9: pixels = 12'b011100011110;
				  4'd10: pixels = 12'b011100001110;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // H
			 5'd11: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001100001100;
				  4'd2: pixels = 12'b001100001100;
				  4'd3: pixels = 12'b001100001100;
				  4'd4: pixels = 12'b001111111100;
				  4'd5: pixels = 12'b001111111100;
				  4'd6: pixels = 12'b001100001100;
				  4'd7: pixels = 12'b001100001100;
				  4'd8: pixels = 12'b001100001100;
				  4'd9: pixels = 12'b001100001100;
				  4'd10: pixels = 12'b001100001100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // Y
			 5'd12: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b011100001110;
				  4'd2: pixels = 12'b011100001110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b001110011100;
				  4'd5: pixels = 12'b001111111100;
				  4'd6: pixels = 12'b000011110000;
				  4'd7: pixels = 12'b000011110000;
				  4'd8: pixels = 12'b000011110000;
				  4'd9: pixels = 12'b000011110000;
				  4'd10: pixels = 12'b000011110000;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // T
			 5'd13: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b011111111110;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b000011110000;
				  4'd4: pixels = 12'b000011110000;
				  4'd5: pixels = 12'b000011110000;
				  4'd6: pixels = 12'b000011110000;
				  4'd7: pixels = 12'b000011110000;
				  4'd8: pixels = 12'b000011110000;
				  4'd9: pixels = 12'b000011110000;
				  4'd10: pixels = 12'b000001100000;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // M
			 5'd14: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b011100001110;
				  4'd2: pixels = 12'b011110011110;
				  4'd3: pixels = 12'b011111111110;
				  4'd4: pixels = 12'b011111111110;
				  4'd5: pixels = 12'b011101101110;
				  4'd6: pixels = 12'b011100001110;
				  4'd7: pixels = 12'b011100001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011100001110;
				  4'd10: pixels = 12'b011100001110;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // S
			 5'd15: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011100000000;
				  4'd5: pixels = 12'b001111111000;
				  4'd6: pixels = 12'b000111111100;
				  4'd7: pixels = 12'b000000011100;
				  4'd8: pixels = 12'b011100011100;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // C
			 5'd16: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011100000000;
				  4'd5: pixels = 12'b011100000000;
				  4'd6: pixels = 12'b011100000000;
				  4'd7: pixels = 12'b011100000000;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // O
			 5'd17: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111100;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100001110;
				  4'd4: pixels = 12'b011100001110;
				  4'd5: pixels = 12'b011100001110;
				  4'd6: pixels = 12'b011100001110;
				  4'd7: pixels = 12'b011100001110;
				  4'd8: pixels = 12'b011100001110;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111100;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
		
			 // E
			 5'd18: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b001111111110;
				  4'd2: pixels = 12'b011111111110;
				  4'd3: pixels = 12'b011100000000;
				  4'd4: pixels = 12'b011100000000;
				  4'd5: pixels = 12'b011111111100;
				  4'd6: pixels = 12'b011111111100;
				  4'd7: pixels = 12'b011100000000;
				  4'd8: pixels = 12'b011100000000;
				  4'd9: pixels = 12'b011111111110;
				  4'd10: pixels = 12'b001111111110;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
				  endcase 
				  
			 // E
			 5'd19: case (row)
				  4'd0: pixels = 12'b000000000000;
				  4'd1: pixels = 12'b000000000000;
				  4'd2: pixels = 12'b000000000000;
				  4'd3: pixels = 12'b000000000000;
				  4'd4: pixels = 12'b000000000000;
				  4'd5: pixels = 12'b000000000000;
				  4'd6: pixels = 12'b000000000000;
				  4'd7: pixels = 12'b000000000000;
				  4'd8: pixels = 12'b000000000000;
				  4'd9: pixels = 12'b000000000000;
				  4'd10: pixels = 12'b000000000000;
				  4'd11: pixels = 12'b000000000000;
				  default: pixels = 12'b000000000000;
			 endcase
			 endcase
	
 
    end
 endmodule








