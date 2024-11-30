
# base address for current drumpad counts
`define DRUMPAD_COUNT_BASE_ADDR $4000
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

`define WINDOW_LENGTH_MS $1000

  MOVW $65000 %SP

# reset initially
  MOVW .sync_reset %rC 
  JAL %RA %rC
  MOVW .drumpads_clear %rC 
  JAL %RA %rC

# store 0 to hex low
  MOVI $0 %rA
  MOVW `HEX_LOW_ADDR %rC 
  STOR %rA %rC

# store 16 to hex high 
  MOVI $16 %rA 
  ADDI $1 %rC
  STOR %rA %rC

.main_loop 

# process drumpad inputs
  MOVW .drumpads_process_input %rC 
  JAL %RA %rC
# write drumpad input state to leds
  MOVW .drumpads_write_to_leds %rC 
  JAL %RA %rC

  MOVW .sync_update %rC 
  JAL %RA %rC
  CMPI $1 %rA     # if returned 1, new window reached
  BEQ ._new_window
  BUC .main_loop

._new_window
# new window reached, store window count to hex low
  MOVW `HEX_LOW_ADDR %r1
  MOVW `CURRENT_WINDOW_ADDR %rC
  LOAD %r0 %rC
  STOR %r0 %r1

  MOVW .drumpads_clear %rC    # clear drumpads
  JAL %RA %rC

# store 32 to hex high 
  MOVW `HEX_HIGH_ADDR %rC
  MOVI $32 %r0 
  STOR %r0 %rC

  BUC .main_loop


# The procedures in this file handle syncronization of the game by updating a 
# global data structure which will contain the current window, and window offset.
# This effectively means that this code will track the progress through the song.
# 
# The procedures in this file are the only ones that should access the hardware 
# millisecond timer. This should help to keep code a bit easeir to debug.

# resets the timer back to start
.sync_reset 
  MSCR    # reset counter
# reset music playback
  MOVW `RESET_MUSIC %rA
  MOVW `MUSIC_CTRL_ADDR %rB
  STOR %rA %rB

# set current window number to 0 
  MOVI $0 %rA 
  MOVW `CURRENT_WINDOW_ADDR %rC
  STOR %rA %rC
# set current window offset to 0
  ADDI $1 %rC
  STOR %rA %rC
# set ms of current window start to 0 
  ADDI $1 %rC 
  STOR %rA %rC
# unset reset on music playback
  STOR %rA %rB
  JUC %RA


# reads timer and updates the current time state of the game
.sync_update 
  SUBI $1 %SP 
  STOR %r0 %SP
  SUBI $1 %SP 
  STOR %r1 %SP

# read switches 
  MOVW `SW_ADDR %r0 
  LOAD %r0 %r0
# decide if should pause game (switch 1)
  MOVI $2 %rB   # for comparison
  AND %r0 %rB   
  CMPI $0 %rB 
  BEQ .__sync_update_unpause
  MOVW ._sync_pause %rC 
  SUBI $1 %SP 
  STOR %RA %SP
  JAL %RA %rC   # pause
  LOAD %RA %SP 
  ADDI $1 %SP
# unpause
.__sync_update_unpause
  MOVW ._sync_unpause %rC 
  SUBI $1 %SP
  STOR %RA %SP
  JAL %RA %rC     # unpause
  LOAD %RA %SP
  ADDI $1 %SP
# decide if should reset game (switch 0)
  MOVI $1 %rB
  AND %r0 %rB
  CMPI $0 %rB
  BEQ .__sync_update_window
  MOVW .sync_reset %rC
  SUBI $1 %SP 
  STOR %RA %SP
  JAL %RA %rC       # reset game
  LOAD %RA %SP 
  ADDI $1 %SP
  MOVI $1 %rA       # return 1
  BUC .__sync_update_end

.__sync_update_window
# if next window reached, update current window number
  MOVW `CURRENT_WINDOW_ADDR %rB 
  ADDI $2 %rB       # adderess of previous window start ms
  LOAD %rC %rB      # load previous window start ms
  MSCG %r0      # get current ms 
  MOV %r0 %r1   # move ms count
  SUB %rC %r1   # calculate window offset
  MOVW `WINDOW_LENGTH_MS %rA
  CMP %r1 %rA
  BLT .__sync_update_same_window    # go to end of proc if current window hasn't reached end
# store new ms of next window start 
  STOR %r0 %rB
# set window offset to 0
  SUBI $1 %rB
  MOVI $0 %rA
  STOR %rA %rB
# increment window
  SUBI $1 %rB   # new address
  LOAD %rC %rB  # load old window value
  ADDI $1 %rC   # increment
  STOR %rC %rB  # store new value
# set return value to 1 
  MOVI $1 %rA
  BUC .__sync_update_end

.__sync_update_same_window
  # set ms offset
  SUBI $1 %rB
  STOR %r1 %rB
  # return value 0
  MOVI $0 %rA

.__sync_update_end
  LOAD %r0 %SP 
  ADDI $1 %SP
  LOAD %r1 %SP 
  ADDI $1 %SP
  JUC %RA


# pause game 
._sync_pause 
  MSCP $1   # pause millisecond counter
  MOVW `PAUSE_MUSIC %rA
  MOVW `MUSIC_CTRL_ADDR %rB
  STOR %rA %rB
  JUC %RA


._sync_unpause
  MSCP $0     # unpause millisecond counter
  MOVI $0 %rA 
  MOVW `MUSIC_CTRL_ADDR %rB
  STOR %rA %rB
  JUC %RA



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

# writes the drumpad data structure to the leds
.drumpads_write_to_leds
#  SUBI $1 %SP
#  STOR %r0 %SP
#  SUBI $1 %SP
#  STOR %r1 %SP
#  SUBI $1 %SP
#  STOR %r2 %SP

  MOVI $0 %rA   # drumpad count
  MOVI $0 %rC   # collecter
  MOVW `DRUMPAD_COUNT_BASE_ADDR %rD
._drumpads_collect_data_loop
  LOAD %rB %rD      # load
  ADD %rB %rC     # collect

  CMPI $3 %rA   
  BEQ ._drumpads_write_to_leds # branch if processed drumpad three (most significant)
  ADDI $1 %rA
  ADDI $1 %rD
  BUC ._drumpads_collect_data_loop
._drumpads_write_to_leds
  MOVW `LEDS_ADDR %rD
  STOR %rC %rD

#  LOAD %r2 %SP 
#  ADDI $1 %SP
#  LOAD %r1 %SP 
#  ADDI $1 %SP
#  LOAD %r2 %SP 
#  ADDI $1 %SP
  JUC %RA
