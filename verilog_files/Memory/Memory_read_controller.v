/*
* Controls reads on the second port of memory, as this port 
* has to be shared between the audio mixer, and the VGA bitgen.
* One port to this controller can access memory unrestricted, 
* and the other port may have to wait to recieve data.
*/
module Memory_read_controller(
  input [17:0] priority_addr, 
  input priority_rd_en, 

  input [17:0] secondary_addr, 

  output [17:0] addr_to_mem, 
  
  output secondary_rd_data_valid,
); 

  // on read, indicate which data was read
  always @(negedge clk) begin 
    secondary_rd_data_valid = ~priority_rd_en;
  end

  // select address
  assign addr_to_mem = priority_rd_en ? priority_addr : secondary_addr;

endmodule
