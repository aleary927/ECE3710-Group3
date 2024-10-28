
// Data path module
module DATA_PATH(
    input clk,
    input reset,
    // Control signals
    input wr_en,                // Write enable for register file
    input alu_src,              // ALU source select
    input mem_wr_en,            // Memory write enable
    input pc_en,                // Program counter enable
    input instr_en,             // Instruction register enable
    input cmp_f_en, of_f_en, z_f_en,  // Processor status register flags enables
    input [1:0] pc_addr_mode,   // PC ALU addressing mode select
    input write_back_sel, // Select for write-back data
   
    // Outputs for testing
    output [15:0] alu_out,      // ALU output
    output [15:0] mem_data_out, // Data read from memory
	 output [3:0] opcode, 
	 output [15:0] psr_out
);

    // Internal wires
    wire [15:0] reg_data1, reg_data2;      // Data read from register file
    wire [15:0] alu_input_b;               // ALU second operand
    wire [15:0] mem_rd_data1, mem_rd_data2;// Data read from memory
    wire [11:0] proc_instr;                // Current instruction
    wire [3:0] proc_opcode;                // Current opcode
    wire [15:0] alu_result;                // ALU result
    wire [20:0] next_pc;                   // Next program counter value
    wire [15:0] write_back_data;            // Data selected for writing back to the register file
	 
	 
	 reg [20:0] pc_current; 
	 wire [15:0] immediate; 

    // Processor Registers
    wire C_out, L_out, F_out, Z_out, N_out; // ALU flags
    
    // Processor Status Register (PSR)
    wire [15:0] psr;

	 
	// PC UPDATED HERE INSTEAD OF IN PROCREGS 	
	initial begin
		pc_current <= 21'd0;
	end
		
	always @(posedge clk) begin
    if (reset)
        pc_current <= 21'd0; // Reset the program counter to 0 if reset 
    else if (pc_en)
        pc_current <= next_pc; 
	end

    // Instantiate the Instruction Register
    instruct_reg instruction_register (
        .clk(clk),
        .instr_en(instr_en),
        .instruct_data(mem_rd_data2),   // instruction from memory 
        .instructions(proc_instr),
        .opcode(proc_opcode)
    );

	 // REGISTERS ARE 4 BITS EACH, COULD ASSIGN 7:0 TO BOTH SECOND REG ADDRESS AND IMMEDIATE 
	 // BUT COMPLICATES DESIGN, IMMEDIATE VALUE IS CURRENTLY 4 BITS, COULD INCREASE BY DECREASING 
	 // THE NUMBER OF REGISTER ADDRESSES. 
    // Instantiate the Register File
    RF register_file (
        .clk(clk),
        .wr_en(wr_en),
        .wr_data(write_back_data), // Use the selected write-back data
        .addr1(proc_instr[11:8]),  // Source register 1
        .addr2(proc_instr[7:4]),   // Source register 2
        .rd_data1(reg_data1),
        .rd_data2(reg_data2)
    );

	 // For output
	 assign opcode = proc_opcode; 
	 
	 
	 
    // ALU Operand B Mux: Select between immediate and register value
    assign alu_input_b = alu_src ? immediate : reg_data2;
	 
	 
	 // Sign extension for the immediate value 
	 assign immediate = {{12{proc_instr[3]}},proc_instr[3:0]};


    // Instantiate the ALU, COULD ADD AN ALU CONTROL MODULE AS WELL
    ALU #(16) alu (
        .a(reg_data1),
        .b(alu_input_b),
        .select(proc_opcode), // Use the derived ALU control signal
        .out(alu_result),
        .C(C_out),
        .L(L_out),
        .F(F_out),
        .Z(Z_out),
        .N(N_out)
    );
	 

    // Instantiate the Memory Module
    Memory #(16, 1024) memory (
        .clk(clk),
        .wr_en1(mem_wr_en),
        .wr_en2(1'b0), // instruction memory read only
        .addr1(alu_result[9:0]),  // ADDRESS CALC THROUGH ALU
        .addr2(pc_current[9:0]),  // ADDRESS CALC THROUGH PC       
        .wr_data1(reg_data2),
        .wr_data2(16'b0),                 // read only
        .rd_data1(mem_rd_data1),
        .rd_data2(mem_rd_data2)
    );

    // Write-Back Mux: Select data to write back to register file, COULD ALSO extend to include immediate. 
	 
	assign write_back_data = write_back_sel ? mem_rd_data1 : alu_result;

	
	
    // Instantiate the Processor Registers THIS ONLY INCLUDES PSR OTHERS ARE HANDLED ABOVE. 
    ProcRegs processor_registers (
        .clk(clk),
        .reset(reset),
        .cmp_f_en(cmp_f_en),
        .of_f_en(of_f_en),
        .z_f_en(z_f_en),
        .C_in(C_out),
        .L_in(L_out),
        .F_in(F_out),
        .Z_in(Z_out),
        .N_in(N_out),
        .psr(psr)
    );

    // Instantiate the PC_ALU for calculating the next program counter
	 // THIS USES A 16 BIT IMMEDIATE VALUE, WHEN THE SPLICED VALUE IS 4 BITS, AGAIN A REDUCTION
	 // IN NUMBER OF REG ADDRESSES AND OPCODES COULD CHANGE THIS. 
    PC_ALU pc_alu (
        .c_pc(pc_current),
        .imm(immediate),
        .addr_mode(pc_addr_mode),
        .n_pc(next_pc)
    );

    // Output assignments for testing
    assign alu_out = alu_result;
    assign mem_data_out = mem_rd_data1;
	 assign psr_out = psr; 

endmodule
