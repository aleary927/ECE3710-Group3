# This file has procedures for directy dealing with the drumpad inputs. No 
# other code will directly access the drumpads.

# process the input, keeps track of the number of times each pad was struck since last clear
.drumpads_process_input
# add space for caller saved registers that will be used
  SUBI $1 %SP 
  STOR %r0 %SP 
  SUBI $1 %SP 
  STOR %r1 %SP
  SUBI $1 %SP 
  STOR %r2 %SP

# load address for drumpad data structure 
  MOVW `DRUMPAD_COUNT_BASE_ADDR %r0

# load drumpad input addr
  MOVW `DRUMPAD_ADDR %rA
  LOAD %rA %rA      # load drumpad input to rA

  MOVI `NUM_DRUMPADS %rB    # load value for number of drumpads
  SUBI $1 %rB       # subtract 1 to get number of highest drumpad
  MOVI $1 %rC       
  LSH %rB %rC       # shift 1  left by most significant drumpad to get first bitmask

.__drumpad_input_loop
  MOV %rC %rD     # move bitmask 
  AND %rA %rD     # apply bitmask

# load current value, add, and store back
  MOV %r0 %r1 
  ADD %rB %r1   # calc address by adding offset to base
  LOAD %r2 %r1  # load previous value
  OR %rD %r2    # or so that it keeps its high value if it was already high
  STOR %r2 %r1  # store new value

  CMPI $0 %rB      # compare to 0 to determine if processed least significant drumpad 
  BEQ .__drumpad_input_end

# setup next loop
  LSHI $-1 %rC    # shift bitmask right by 1
  SUBI $1 %rB     # decrement drumpad count

  BUC .__drumpad_input_loop

.__drumpad_input_end
# restore registers 
  LOAD %r2 $SP 
  ADDI $1 %SP 
  LOAD %r1 %SP 
  ADDI $1 %SP 
  LOAD %r0 %SP 
  ADDI $1 %SP
  JUC %RA


# clears the current inputs (resets each pad's count back to 0)
.drumpads_clear
# load address for drumpad data structure 
  MOVW `DRUMPAD_COUNT_BASE_ADDR %rD

  MOVI `NUM_DRUMPADS %rB    # load value for number of drumpads

  MOVI $0 %rC   # load zero

.__drumpad_clear_loop 
  SUBI $1 %rB       # subtract 1 to get offset of next drumpad
  MOV %rD %rA       # move base address 
  ADD %rB %rA       # calculate address of drumpad
  STOR %rC %rA      # store zero to drumpad address

# loop again if already cleared least significant drumpad
  CMPI $0 %rB   
  BNE .__drumpad_clear_loop

  JUC %RA

