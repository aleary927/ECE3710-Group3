# The procedures in this file handle syncronization of the game by updating a 
# global data structure which will contain the current window, and window offset.
# This effectively means that this code will track the progress through the song.
# 
# The procedures in this file are the only ones that should access the hardware 
# millisecond timer. This should help to keep code a bit easeir to debug.

`define WINDOW_LENGTH_MS 1000

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
  STOR %rA, %rC
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
# decide if should reset game (switch 1)
  MOVI $1 %rB
  AND %r0 %rB
  CMPI $0 %rB
  BEQ .__sync_update_skip_reset
  MOVW .sync_reset %rC
  JAL %RA %rC       # reset game

.__sync_update_skip_reset
# decide if should pause game (switch 2)
  MOVI $2 $rB 
  AND %r0 %rB 
  CMPI $0 %rB 
  BEQ .__sync_update_unpause
  MOVW ._sync_pause %rC 
  JAL %RA %rC   # pause
  BUC .__sync_update_window

.__sync_update_unpause
  MOVW ._sync_unpause %rC 
  JAL %RA %rC     # unpause

.__sync_update_window
# if next window reached, update current window number
  MOVW `CURRENT_WINDOW_ADDR %rB 
  ADDI $2 %rB       # adderess of previous window start ms
  LOAD %rC %rB
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
  STOR $0 %rB
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
