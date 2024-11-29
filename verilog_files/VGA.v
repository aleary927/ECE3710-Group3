	module VGA (input clk, 
					output [7:0]VGA_RED, VGA_GREEN, VGA_BLUE, 
					output VGA_CLK,     // VGA pixel clock (25MHz)
					output VGA_BLANK_N, // Active-low blanking signal
					output VGA_HS,      // Horizontal sync output
					output VGA_SYNC_N, // assign low
					output VGA_VS);       // added here for desired T-Bird behavior

		// here will be using h_count and v_count and bright for pixels 
		// connect hsync and vsync to VGA_HS and VGA_VS signals 

		 wire hSync, vSync, bright;
		 wire [9:0] hCount, vCount;
		 wire En; 
		 
		 wire [2:0] rgb; 
		 
		 wire [3:0] new_tile; 
		
	
		 
		 wire [3:0] live_tile; 
		  
				 
		 
		wire [9:0] y_pos_one; 
		wire [9:0] y_pos_two; 
		wire [9:0] y_pos_three; 
		wire [9:0] y_pos_four; 
		
		wire [6:0] block_speed; 
	

		
		
		wire dead1; 
		wire dead2;
		wire dead3;
		wire dead4;
		
		
	 reg [7:0] mem [0:255];  // WILL BE IN INPUT TO THE VGA
	 
    reg [7:0] mem_data_in;  
    reg mem_read_done;    

    wire [6:0] speed;
    wire [15:0] mem_address;
    wire mem_read_en;
	 

		
		
		  // Memory Read Logic
    always @(posedge clk) begin
        if (mem_read_en) begin
            mem_data_in <= mem[mem_address];  // Fetch data from memory
            mem_read_done <= 1;              // Assert read-done signal
        end else begin
            mem_read_done <= 0;              // Deassert read-done signal
        end
    end

    // Instantiate mem_interface
    mem_interface #(.INDEX(240)) u_mem_interface (
        .clk(clk),
        .mem_data_in(mem_data_in),
        .mem_read_done(mem_read_done),
        .new_tile(new_tile),
        .speed(block_speed),
        .mem_address(mem_address),
        .mem_read_en(mem_read_en)
    );
		 
		 assign live_tile = new_tile;
		 
		 
		 
		SlowMover mover_one (
		 .clk(clk), 
		 .live(new_tile[0]),
		 .BLOCK_SPEED(block_speed),
		 .dead(dead1),
		 .y_pos(y_pos_one) 
		);
		
		SlowMover mover_two (
		 .clk(clk), 
		 .live(new_tile[1]),
		 .BLOCK_SPEED(block_speed),
		 .dead(dead2),
		 .y_pos(y_pos_two)
		);
		
		SlowMover mover_three (
		 .clk(clk), 
		 .live(new_tile[2]),
		 .BLOCK_SPEED(block_speed), 
		 .dead(dead3),
		 .y_pos(y_pos_three)
		);
		
		SlowMover mover_four (
		 .clk(clk),   
		 .live(new_tile[3]),	
		 .BLOCK_SPEED(block_speed), 
		 .dead(dead4), 
		 .y_pos(y_pos_four)
		);
		


		 
		 
		 
		 

		 // Instantiate the vgaControl module
		 vgaControl vgaInst (
			  .clk(clk),       
			  .clr(1'b1),       
			  .hSync(hSync),   
			  .vSync(vSync),    
			  .bright(bright),  
			  .hCount(hCount),   
			  .vCount(vCount),   
			  .En(En)       //vga clock
		 );
			 
			 
			 // Instantiate the bitGen_Glyph module
		bitGen_Glyph glyph_inst (
			 .clk(clk),                 
			 .live_tile(live_tile),  // was new_tile   
			 .h_count(hCount),           
			 .v_count(vCount), 
			 .y_pos_one(y_pos_one),
			 .y_pos_two(y_pos_two),
			 .y_pos_three(y_pos_three),
			 .y_pos_four(y_pos_four),
			 .dead1(dead1), 
			 .dead2(dead2), 
			 .dead3(dead3), 
			 .dead4(dead4), 
			 .rgb(rgb)                   
		);
		

		 
		 

		 
		 assign VGA_CLK = En;        // My 25Mhz clock
												 
		 assign VGA_SYNC_N = 1'b0;
		 
		 assign VGA_BLANK_N = bright; // Active low signal: invert the bright signal for blanking
		 assign VGA_HS = hSync;       // Connect horizontal sync
		 assign VGA_VS = vSync;       // Connect vertical sync
		 
		 
		 assign VGA_RED = {8{rgb[2]}}; // concatenate each to 8 bit value. 
		 assign VGA_GREEN = {8{rgb[1]}}; 
		 assign VGA_BLUE = {8{rgb[0]}}; 


	endmodule



		
	module bitGen_Glyph (
		 input clk,                // System clock
		 input [3:0] live_tile, 
		 input [9:0] h_count,      // Current pixel x-coordinate
		 input [9:0] v_count,      // Current pixel y-coordinate
		 input [9:0] y_pos_one, //[NUM_LANES-1:0], //[MAX_TILES-1:0]
		 input [9:0] y_pos_two,
		 input [9:0] y_pos_three,
		 input [9:0] y_pos_four, 
		 input dead1, 
		 input dead2, 
		 input dead3, 
		 input dead4,
		 output reg [2:0] rgb      // RGB output
	);

		 // Parameters for screen and lane dimensions
		 parameter SCREEN_WIDTH = 640;
		 parameter SCREEN_HEIGHT = 480;
		 parameter NUM_LANES = 6;                     // Number of black lanes
		 parameter LANE_WIDTH = SCREEN_WIDTH / NUM_LANES; // Width of each lane
		 parameter LINE_WIDTH = 2;                   // Thickness of the white lines
		 
		 parameter BLOCK_LENGTH = 90; 
		 
			wire [9:0] y_position;

		 always @(*) begin
			  // Default background color: black
			  rgb = 3'b000; // Black
			  
			  if(h_count <(106)) begin 
						rgb = 3'b011;
			  end 
			  
			  
			  if((h_count >= 106 && h_count < 108) ||
				 (h_count >= 212 && h_count < 214) ||
				 (h_count >= 318 && h_count < 320) ||
				 (h_count >= 424 && h_count < 426) ||
				 (h_count >= 528 && h_count < 530)) begin
				 rgb = 3'b111; // White
			  end
			  

			  if (h_count >= 108 && h_count < 212 && v_count >= 450) begin
					 rgb = 3'b100;
				end
				else if (h_count >= 214 && h_count < 318 && v_count >= 450) begin
					 rgb = 3'b101;
				end
				else if (h_count >= 320 && h_count < 424 && v_count >= 450) begin
					 rgb = 3'b010;
				end
				else if (h_count >= 426 && h_count < 528 && v_count >= 450) begin
					 rgb = 3'b110;
				end

			  
			  if(h_count >= (530)) begin 
						rgb = 3'b011;
			  end 
			  
			  
			
			// loop y_position[0]
		 if (!dead1 && live_tile[0] && h_count >= 108 && h_count < 212 && 
			  v_count >= y_pos_one && v_count < y_pos_one + BLOCK_LENGTH && (y_pos_one + BLOCK_LENGTH) < 450) begin
			  
			  
			  rgb = 3'b111; 
		 end

			 // loop y_position [1]
		 if (!dead2 && live_tile[1] && h_count >= 214 && h_count < 318 && 
			  v_count >= y_pos_two && v_count < y_pos_two + BLOCK_LENGTH && (y_pos_two + BLOCK_LENGTH) < 450) begin
			  rgb = 3'b111; 
		 end

	  
			// loop y_position [2]
		 if (!dead3 && live_tile[2] && h_count >= 320 && h_count < 424 && 
			  v_count >= y_pos_three && v_count < y_pos_three + BLOCK_LENGTH && (y_pos_three + BLOCK_LENGTH) < 450) begin
			  rgb = 3'b111; 
		 end

	 
		 // loop y_position [3]
		 if (!dead4 && live_tile[3] && h_count >= 426 && h_count < 528 && 
			  v_count >= y_pos_four && v_count < y_pos_four + BLOCK_LENGTH && (y_pos_four + BLOCK_LENGTH) < 450) begin
			  rgb = 3'b111; 

	end

			  
			  
			  
			
		 end

	endmodule






	module SlowMover(
		 input clk,               
		 input live, 
		 input [6:0] BLOCK_SPEED, 
		 output reg dead, 
		 output reg [9:0] y_pos    // Y-coordinate of the block
	);

		 parameter BLOCK_LENGTH = 90; 
		 parameter CLOCK_FREQ = 50000000;     

		 reg [25:0] counter;      // 26-bit counter for clock cycles
		 reg [25:0] max_count;    // Dynamic max count based on BLOCK_SPEED

		 // Initialize signals
		 initial begin
			  y_pos = 0;
			  counter = 0;
			  dead = 0;
		 end

		 always @(posedge clk) begin
			  if (!live) begin
					// Reset on not live
					counter <= 0;
					dead <= 0;
			  end else begin
					// Dynamically update max_count based on BLOCK_SPEED
					max_count <= CLOCK_FREQ / BLOCK_SPEED;

					// Increment counter and update Y-position
					if (counter >= max_count - 1) begin
						 counter <= 0;           // Reset counter
						 y_pos <= y_pos + 1;     // Increment Y-position
					end else begin
						 counter <= counter + 1; // Increment counter
					end

					// Check for out-of-bounds and set dead signal
					if ((y_pos + BLOCK_LENGTH) > 450) begin
						 dead <= 1;  // Set dead signal
					end
			  end
		 end
	endmodule



	module mem_interface #(parameter INDEX = 0)( // CHANGE INDEX HERE
		 input clk,                        
		 input [7:0] mem_data_in,          
		 input mem_read_done,              
		 output reg [3:0] new_tile,        
		 output reg [6:0] speed, 
		 output reg [15:0] mem_address,   
		 output reg mem_read_en       
	);

		 // base index for speed and tile data
		 parameter SPEED_OFFSET = 0;    // REPRESENTATIVE OF SONG TEMPO, NEEDS TO BE CONSTANT FOR THIS VGA 
		 parameter TILE_OFFSET = 1;    // REPRESENTATIV OF TILE ADDRESS DILE DEACTIVATION IS HANDLED IN BITGEN
												 // SHOULD PROBABLY BE CHANGED LATER. 

		 reg [1:0] state;                 // FSM state
		 reg [3:0] live_tile;             // Local register for live tile management

		 // FSM States
		 localparam IDLE = 2'b00;
		 localparam READ_SPEED = 2'b01;
		 localparam READ_TILE = 2'b10;

		 initial begin
			  state = IDLE;
			  mem_read_en = 0;
			  new_tile = 4'b0000;
			  speed = 7'd0;
			  live_tile = 4'b0000;
		 end

		 always @(posedge clk) begin
		 
			  case (state)
					IDLE: begin
						 // Start by reading the speed
						 mem_address <= INDEX + SPEED_OFFSET; // Address for speed
						 mem_read_en <= 1;                   // Enable memory read
						 state <= READ_SPEED;
					end

					READ_SPEED: begin
						 if (mem_read_done) begin
							  speed <= mem_data_in[6:0];       // Extract speed from memory
							  mem_address <= INDEX + TILE_OFFSET; // Address for tile data
							  mem_read_en <= 1;               // Enable tile memory read
							  state <= READ_TILE;
						 end else begin
							  mem_read_en <= 0;               // Disable read enable
						 end
					end

					READ_TILE: begin
						 if (mem_read_done) begin
							  live_tile <= mem_data_in[3:0];   // Extract live tile status
							  new_tile <= live_tile;          // Update new tile signal
							  state <= IDLE;
						 end else begin
							  mem_read_en <= 0;               // Disable read enable
						 end
					end

			  endcase
		 end
	endmodule




