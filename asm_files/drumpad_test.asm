# base address for current drumpad counts
`define DRUMPAD_COUNT_BASE_ADDR $30000
# number of drumpads
`define NUM_DRUMPADS $4

# base address for game state data structure
`define GAME_STATE_BASE_ADDR $5000

# syncroniaztion data structure
`define CURRENT_WINDOW_ADDR $6000

# value to load to music_ctrl to pause music
`define PAUSE_MUSIC $1
`define RESET_MUSIC $2

`define SW_ADDR $65535 
`define BTNS_ADDR $65534 
`define LEDS_ADDR $65533 
`define HEX_HIGH_ADDR $65532 
`define HEX_LOW_ADDR $65531 
`define VGA_HCOUNT_ADDR $65530
`define VGA_VCOUNT_ADDR $65529
`define MUSIC_CTRL_ADDR $65528
`define DRUMPAD_ADDR $65527

# initial value for stack
`define STACK_INIT $65500

# init stack
  MOVW `STACK_INIT %SP
# start here
  MOVW .drumpads_clear %r0 
  JAL %RA %r0
  MSCR 
  MSCP $0

  MOVI $64 %r8
  MOVW `HEX_HIGH_ADDR %r7
  STOR %r8 %r7

.main_loop 
# process drumpad inputs
  MOVW .drumpads_process_input %r0
  JAL %RA %r0

  MOVI $0 %r1   # drumpad count
  MOVI $0 %rC   # collect
  MOVW `DRUMPAD_COUNT_BASE_ADDR %r2
._collect_data_loop
  LOAD %r3 %r2
  ADD %r3 %rC

  CMPI $3 %r1
  BEQ ._write_to_leds # branch if processed drumpad three
  ADDI $1 %r1
  ADDI $1 %r2
  BUC ._collect_data_loop

._write_to_leds
  MOVW `LEDS_ADDR %r2
  STOR %rC %r2

# read switches, write to music ctrl 
  MOVW `SW_ADDR %rA 
  MOVW `MUSIC_CTRL_ADDR %rB
  LOAD %rA %rA 
  STOR %rA %rB

# check if window has been reached
  MSCG %r0
  MOVW $1000 %r1
  CMP %r1 %r0
  BLE ._clear_drumpads
  BUC .main_loop 

._clear_drumpads 
  MSCR   # reset count 
  MOVW .drumpads_clear %r9
  JAL %RA %r9
  MOVW `HEX_LOW_ADDR %rA
  LOAD %r6 %rA
  ADDI $1 %r6 
  STOR %r6 %rA

  BUC .main_loop




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
  LOAD %r2 %SP 
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

