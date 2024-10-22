module ALUandRF(
    input clk,                   // Clock signal
	 input write_enable,        // write to reg file ? 
   input [1:0] addr,        // addr of reg file selection
   input [1:0] sel,         // alu func select
   input [2:0] a_in, b_in,  // a and b input to ALU
    output [4:0] alu_res, 
    output [4:0] reg_data
);

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam REGBITS = 4;

    // Wires to connect ALU and Register File
    wire [DATA_WIDTH - 1:0] alu_out;  // ALU output
    wire [DATA_WIDTH - 1:0] rd_data1, rd_data2;  // Register file read data
    wire C, L, F, Z, N;               
    wire wr_en;                         
   wire [15:0] psr; 

    // Instantiate the ALU
    ALU #(.DATA_WIDTH(DATA_WIDTH)) alu (
        .a(a_in),
        .b(b_in),
        .select({2'b00, sel}),
        .out(alu_out), //16 bits
        .C(C), .L(L), .F(F), .Z(Z), .N(N)
    );

    // Instantiate the Register File
    RF #(.DATA_WIDTH(DATA_WIDTH), .REGBITS(REGBITS)) rf (
        .clk(clk),
        .wr_en(wr_en),                       
        .cmp_f_en(1'b0), .of_f_en(1'b0), .z_f_en(1'b0), 
        .wr_data(alu_out),                    // 4 bits
        .addr1({2'b00, addr}),                // 4 bits 4'b0000  switches[5:2]
        .addr2(4'b0),                // 4 bits
        .C_in(C), .L_in(L), .F_in(F), .Z_in(Z), .N_in(N), 
        .rd_data1(rd_data1), .rd_data2(rd_data2), // 16 bits
        .psr(psr)                                
    );

  assign wr_en = ~write_enable;

 
  assign alu_res = alu_out[4:0]; 
  assign reg_data = rd_data1[4:0];

endmodule

