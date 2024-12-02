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

   
    reg [3:0] counter;        
     reg [15:0] registers[11:0];      
    reg read_done;             

 
    assign memory_address = STARTING + counter; // Starting at address 240 plus counter
    assign memory_read_enable = (counter < 12) && !read_done;

 
    wire start_memory_reads = (vCount == 0) && (hCount == 0); 

    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            read_done <= 0;
        end 
		  else if (start_memory_reads && !read_done) begin
            counter <= counter + 1;
            if (counter < 12) registers[counter] <= memory_read_data;
				else read_done <= 1;      
        end 
		  
		  else if (!start_memory_reads) begin
            read_done <= 0;
            counter <= 0;
        end
    end

	 
    // Parsing regvalues for lanes
    wire [9:0] mem_y_start_one;
	 wire [9:0] mem_y_start_two;
	 wire [9:0] mem_y_start_three;
	 wire [9:0] mem_y_start_four;
	 
    wire [9:0] mem_y_end_one;
	 wire [9:0] mem_y_end_two;
	 wire [9:0] mem_y_end_three;  
	 wire [9:0] mem_y_end_four;
	 
    wire [2:0] mem_colors_one;
	 wire [2:0] mem_colors_two;
	 wire [2:0] mem_colors_three;
	 wire [2:0] mem_colors_four;
	 
	 // could combine different portions of register bits here, just a representation. 

    assign mem_y_start_one = registers[0][9:0];
    assign mem_y_end_one  = registers[1][9:0];
	 
	 assign mem_colors_one = registers[2][2:0]; ///
	 
    assign mem_y_start_two = registers[3][9:0];
    assign mem_y_end_two  = registers[4][9:0];
	 
	 assign mem_colors_two = registers[5][2:0]; ///
	 
    assign mem_y_start_three = registers[6][9:0];
    assign mem_y_end_three  = registers[7][9:0]; 
	 
	 assign mem_colors_three = registers[8][2:0]; ///
	 
    assign mem_y_start_four= registers[9][9:0];
    assign mem_y_end_four   = registers[10][9:0];
	 
	 assign mem_colors_four = registers[11][2:0]; ///
	 
	

    
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
		 .mem_y_start_one(mem_y_start_one),
		 .mem_y_start_two(mem_y_start_two),
		 .mem_y_start_three(mem_y_start_three),
		 .mem_y_start_four(mem_y_start_four),
		 .mem_y_end_one(mem_y_end_one),
		 .mem_y_end_two(mem_y_end_two),
		 .mem_y_end_three(mem_y_end_three),
		 .mem_y_end_four(mem_y_end_four),
		 .mem_colors_one(mem_colors_one),
		 .mem_colors_two(mem_colors_two),
		 .mem_colors_three(mem_colors_three),
		 .mem_colors_four(mem_colors_four),
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
    input [9:0] mem_y_start_one, // y_start for lane 1
    input [9:0] mem_y_start_two, // y_start for lane 2
    input [9:0] mem_y_start_three, // y_start for lane 3
    input [9:0] mem_y_start_four, // y_start for lane 4
    input [9:0] mem_y_end_one,   // y_end for lane 1
    input [9:0] mem_y_end_two,   // y_end for lane 2
    input [9:0] mem_y_end_three, // y_end for lane 3
    input [9:0] mem_y_end_four,  // y_end for lane 4
    input [2:0] mem_colors_one,  // Color for lane 1
    input [2:0] mem_colors_two,  // Color for lane 2
    input [2:0] mem_colors_three, // Color for lane 3
    input [2:0] mem_colors_four,  // Color for lane 4
    output reg [2:0] rgb      // RGB output
);

    // Parameters for screen and lane dimensions
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter NUM_LANES = 6;                     // Number of black lanes
    parameter LANE_WIDTH = SCREEN_WIDTH / NUM_LANES; // Width of each lane
    parameter LINE_WIDTH = 2;                   // Thickness of the white lines
    parameter BLOCK_LENGTH = 90; 
     
    always @(*) begin
        // Default background color: black
        rgb = 3'b000; // Black
        
		  // background left
        if (h_count < 106) begin 
            rgb = 3'b011;
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
					 rgb = 3'b100;
				end
				// End of lane 2
				else if (h_count >= 214 && h_count < 318 && v_count >= 450) begin
					 rgb = 3'b101;
				end
				// End of lane 3
				else if (h_count >= 320 && h_count < 424 && v_count >= 450) begin
					 rgb = 3'b010;
				end
				// End of lane 4
				else if (h_count >= 426 && h_count < 528 && v_count >= 450) begin
					 rgb = 3'b110;
				end

			  // background right
			  if(h_count >= (530)) begin 
						rgb = 3'b011;
			  end 
		  
		
        // Conditions for each lane
        if (h_count >= 108 && h_count < 212) begin
            if (v_count >= mem_y_start_one && v_count < mem_y_end_one) begin
                rgb = mem_colors_one;
            end
        end

        if (h_count >= 214 && h_count < 318) begin
            if (v_count >= mem_y_start_two && v_count < mem_y_end_two) begin
                rgb = mem_colors_two;
            end
        end
        
        if (h_count >= 320 && h_count < 424) begin
            if (v_count >= mem_y_start_three && v_count < mem_y_end_three) begin
                rgb = mem_colors_three;
            end
        end
        
        if (h_count >= 426 && h_count < 528) begin
            if (v_count >= mem_y_start_four && v_count < mem_y_end_four) begin
                rgb = mem_colors_four;
            end
        end
    end
endmodule



