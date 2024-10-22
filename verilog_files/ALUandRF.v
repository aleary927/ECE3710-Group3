module ALUandRF(
    input clk,                   // Clock signal
	 input led_select,
	 input write_enable,
    input [9:0] switches,        // 10 switches for input (could expand for better control)
    output [9:0] leds            // 10 LEDs for output
);

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam REGBITS = 4;

    // Wires to connect ALU and Register File
    wire [DATA_WIDTH - 1:0] alu_out;  // ALU output
    wire [DATA_WIDTH - 1:0] rd_data1, rd_data2;  // Register file read data
    wire C, L, F, Z, N;               
    reg [DATA_WIDTH - 1:0] a, b;       
    reg [3:0] alu_op;                  
    reg wr_en;                         
	 reg [15:0] psr; 

    // Instantiate the ALU
    ALU_tester #(.DATA_WIDTH(DATA_WIDTH)) alu (
        .a(a),
        .b(b),
        .select(alu_op),
        .out(alu_out), //16 bits
        .C(C), .L(L), .F(F), .Z(Z), .N(N)
    );

    // Instantiate the Register File
    RF_tester #(.DATA_WIDTH(DATA_WIDTH), .REGBITS(REGBITS)) rf (
        .clk(clk),
        .wr_en(wr_en),                       
        .cmp_f_en(1'b0), .of_f_en(1'b0), .z_f_en(1'b0), 
        .wr_data(alu_out),                    // 4 bits
        .addr1(4'b0),                // 4 bits 4'b0000  switches[5:2]
        .addr2(switches[9:6]),                // 4 bits
        .C_in(C), .L_in(L), .F_in(F), .Z_in(Z), .N_in(N), 
        .rd_data1(rd_data1), .rd_data2(rd_data2), // 16 bits
        .psr()                                
    );

	 initial begin
		
	 
	 end
    // Control Logic
    always @(*) begin 
       // Read data from register file
        //a <= rd_data1;           // Operand A from register file
        case (switches[5:3]) 
            3'b000: a = rd_data1;  
            3'b001: a = 16'h0001;  
            3'b010: a = 16'h0002;   
            3'b011: a = 16'h0003;   
            3'b100: a = 16'h0004; 
				3'b101: a = 16'h0005;
				3'b110: a = 16'h0006; 
				3'b111: a = 16'h0007; 
            default: a = rd_data1;  // Default to rd_data1 for other cases
        endcase
		  
		  
		  
		  b <= rd_data2;           // Operand B from register file
        alu_op <= switches[2:0]; // ALU operation selection from switches

       
        wr_en <= !write_enable;   // assigned to button

    end

 
    //assign leds = rd_data1[9:0]; // Display lower 10 bits of ALU result on LEDs WAS 9:0 alu_out[9:0];
	assign leds = alu_out[9:0]; 

endmodule

