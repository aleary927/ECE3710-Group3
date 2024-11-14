# initialize stack pointer (%r15)
  LUI $255 %r13    # all ones in upper 
  MOVI $255 %r15   # all ones in lower
  OR %r13 %r15    # OR for all ones
  SUBI $10 %r15   # size of I/O space
# initialize I/O 

# init fibonacci loop (n = 24)
  MOVI $24 %r0  # init n to 24
  MOVI $255 %r10  # base address for data storage
  SUBI $1 %r15  # space for n on stack
  MOVI .fibn %r8  # address of fibn  
.calc_loop
  # store n 
  STOR %r0 %r15
  # call fibn
  JAL %r14 %r8
  # load n 
  LOAD %r0 %r15 
  # store result 
  MOV %r10 %r11 # move base address
  ADD %r0 %r11  # add n to base as offset
  STOR %r1 %r11 # store result

  CMPI $0 %r0   # compare against 0
  BNE .next_n   # if not zero, loop again
  ADDI $1 %r15  # restore stack
  BUC .read_loop_init  # go to read loop
.next_n
  # decrement n 
  SUBI $1 %r0
  BUC .calc_loop      # go back to fib loop

# fibonacci method 
.fibn 
  CMPI $1 %r0       # compare n to 1 
  BEQ .n_is_one 
  BGT .n_is_zero 
  # save return address
  SUBI $1 %r15  
  STOR %r14 %r15
  # save n
  SUBI $1 %r15 
  STOR %r0 %r15
  # call recursively with n - 1
  SUBI $1 %r0 
  JAL %r14 %r8
  # load n 
  LOAD %r0 %r15   # get n from stack
  # save result
  STOR %r1 %r15   # push result to stack
  # call recusively with n - 2
  SUBI $2 %r0 
  JAL %r14 %r8
  # load n - 1 result 
  LOAD %r2 %r15 
  ADDI $1 %r15 
  # add n - 1 result and n - 2 result 
  ADD %r2 %r1
  # restore stack 
  LOAD %r14 %r15    # load original return address
  ADDI $1 %r15 
  # return result 
  JUC %r14
# return 0
.n_is_zero 
  MOVI $0 %r1 
  JUC %r14
# return 1
.n_is_one 
  MOVI $1 %r1  
  JUC %r14

# load base address for fib vals 
.read_loop_init
  MOVI $255 %r2    # base address for fib vals 
  # load address for switches (%r3)
  MOVI $254 %r3 
  LUI $255 %r4 
  OR %r4 %r3
  # load address for hex (%r4)
  MOVI $251 %r4 
  LUI $255 %r5 
  OR %r5 %r4
# read switches, update hex
.read_loop
  # read offset from switches 
  LOAD %r0 %r3
  # add offset to base address 
  ADD %r2 %r0
  # read fib val 
  LOAD %r1 %r0
  # write to hex
  STOR %r1 %r4
  BUC .read_loop
