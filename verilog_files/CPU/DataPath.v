/*
* Module to handle the flow and storage of data within the CPU.
* 
* This module has enable/control signals inteded to be controlled
* by a separate controller module.
*/

module DataPath(
    input clk,
    input reset_n,
    // Control signals
    input wr_en,                // Write enable for register file
    input alu_src,              // ALU source select
    input [3:0] alu_sel,        // ALU function select
    input next_instr,           // whether to use PC as mem address
    input pc_en,                // Program counter enable
    input instr_en,             // Instruction register enable
    input cmp_f_en, of_f_en, z_f_en,  // Processor status register flags enables
    input [1:0] pc_addr_mode,   // PC ALU addressing mode select
    input [2:0] write_back_sel,   // Select for write-back data to reg file
    input [1:0] sign_ext_mode,
    // timer 
    input timer_pause_en, 
    input timer_reset,
    // mem signals
    input [15:0] mem_rd_data,       // data from memory
    output [15:0] mem_wr_data,      // data to memory
    output [15:0] mem_addr,       // address to memory
    // signals to controller
    output cmp_result,            // result of comparison operations
    output [3:0] opcode, opcode_ext   // opcode and opcode extension
); 

  // **************************
  // INTERNAL WIRES
  // ****************************

  // RF and ALU connectors
  wire [15:0] Rdest_data, Rsrc_data;      // Data read from register file
  wire [15:0] alu_input_b;               // ALU second operand
  wire [15:0] alu_result;                // ALU result
  wire [15:0] write_back_data;            // Data selected for writing back to the register file
  
  // timer wires 
  wire [15:0] ms_count; 
 
  // connector wires for registers
  wire [15:0] pc_current;               // current program counter
  wire [15:0] next_pc;                   // Next program counter value
  wire [15:0] pc_plus_one;        // current pc + 1
  wire [15:0] current_instr;          // current instruction
  wire [15:0] psr;            // processor status

  // signed extended immediate 
  wire [7:0] immediate; 
  wire [15:0] immediate_ext;

  // wires for convenience in accessing Rdest, Rsrc (parts of instruction reg)
  wire [3:0] Rdest, Rsrc;

  // connector wires for ALU flags
  wire C_out, L_out, F_out, Z_out, N_out; 
  
  // ***********************
  // CONNECTOR LOGIC
  // ********************** 

  // write data always comes from Rdest (Rdest_data)
  assign mem_wr_data = Rdest_data;

  // break instruction reg down into parts for controller
  assign opcode = current_instr[15:12];
  assign opcode_ext = current_instr[7:4];

  // separeate Rsrc, Rdest 
  assign Rdest = current_instr[11:8];
  assign Rsrc = current_instr[3:0];

  // for connection to sign extender
  assign immediate = current_instr[7:0];

  // *********************
  // MUXES 
  // **********************

  // Write-Back Mux: Select data to write back to register file, (alu result, 
  // memory read data, register read data, or immediate)
  Mux6 #(16) reg_wr_src (
    .sel(write_back_sel), 
    .a(alu_result), 
    .b(mem_rd_data), 
    .c(Rsrc_data),
    .d(immediate_ext),
    .e(pc_plus_one),    // will only ever need to write pc + 1 to reg
    .f(ms_count),
    .out(write_back_data));

  // ALU Operand B Mux: Select between immediate and register value
  Mux2 #(16) alu_srcb_mux (
    .sel(alu_src), 
    .a(Rsrc_data), 
    .b(immediate_ext), 
    .out(alu_input_b));

  // Memory address output can be either the value in Rsrc (Rsrc_data) or 
  // the PC
  Mux2 #(16) mem_addr_mux (
    .sel(next_instr), 
    .a(Rsrc_data), 
    .b(pc_current), 
    .out(mem_addr));

    // ******************************
    // MODULE INSTANCIATIONS 
    // ******************************

  // instruction registers
  Register #(16) instr_reg (
      .clk(clk), 
      .reset_n(reset_n), 
      .wr_en(instr_en),
      .d(mem_rd_data), 
      .q(current_instr)
  );

  // program counter
  Register #(16) pc (
    .clk(clk), 
    .reset_n(reset_n), 
    .wr_en(pc_en),
    .d(next_pc), 
    .q(pc_current)
  );
  
    // Instantiate the Processor Registers THIS ONLY INCLUDES PSR OTHERS ARE HANDLED ABOVE. 
    PSR proc_stat_reg (
        .clk(clk),
        .reset_n(reset_n),
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

    // Instantiate the Register File
    RF register_file (
        .clk(clk),
        .wr_en(wr_en),
        .wr_data(write_back_data), // Use the selected write-back data
        .addr1(Rdest),  // Source register 1
        .addr2(Rsrc),   // Source register 2
        .rd_data1(Rdest_data),
        .rd_data2(Rsrc_data)
    );

    // Instantiate the ALU 
    ALU #(16) alu (
        .a(Rdest_data),
        .b(alu_input_b),
        .select(alu_sel), 
        .out(alu_result),
        .C(C_out),
        .L(L_out),
        .F(F_out),
        .Z(Z_out),
        .N(N_out)
    );

   // Instantiate the PC_ALU for calculating the next program counter
   PC_ALU #(16) pc_alu (
        .c_pc(pc_current),      // current program counter
        .offset(immediate_ext),     // for branches
        .target(Rsrc_data),     // for jumps
        .addr_mode(pc_addr_mode), // select addressing mode
        .pc_plus_one(pc_plus_one),  // current pc + 1
        .n_pc(next_pc)          // next program counter
   );

   MS_counter ms_counter ( 
     .clk(clk), 
     .reset_n(reset_n), 
     .user_reset(timer_reset), 
     .config_en(timer_pause_en),
     .pause(immediate_ext[0]),      // use LSB of immediate for 
     .count(ms_count)
   );

   // perform sign extension 
   ImmExtender sign_extend (
      .imm(immediate), 
      .mode(sign_ext_mode), 
      .ext(immediate_ext)
   );

   // Comparator to use a mnemonic (encoded in Rdest) and the comparison 
   // flags in order to generate a signal to the controller indicating whether 
   // or not to branch
   Comparator cmp (
     .mnemonic(Rdest), 
     .psr(psr), 
     .result(cmp_result)
   );

endmodule
