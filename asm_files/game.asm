##########################################################################
# Music Tiles Game Code
# 
##########################################################################

############################## 
# MACRO DEFINITIONS
##############################

# base address for current drumpad counts
`define DRUMPAD_COUNT_BASE_ADDR $32000
# number of drumpads
`define NUM_DRUMPADS $4

`define GAME_SCORE_ADDR $31000

`define GRAPHICS_BASE_ADDR $65500

# syncroniztion data structure
`define CURRENT_WINDOW_ADDR $30000

`define WINDOW_DATA_BASE_ADDR $5000

# sum of vcount and hcount to trigger refresh
`define VGA_VCOUNT_REFRESH_VAL $479

# value to load to music_ctrl to pause music
`define PAUSE_MUSIC $1
`define RESET_MUSIC $2

# addresses for memory-mapped peripherals
`define SW_ADDR $65535 
`define BTNS_ADDR $65534 
`define LEDS_ADDR $65533 
`define HEX_HIGH_ADDR $65532 
`define HEX_LOW_ADDR $65531 
`define VGA_HCOUNT_ADDR $65530
`define VGA_VCOUNT_ADDR $65529
`define MUSIC_CTRL_ADDR $65528
`define DRUMPAD_ADDR $65527
`define MUSIC_STATE_ADDR $65526

# number of milliseconds per window
`define WINDOW_LENGTH_MS $1000

`define INIT_SCORE $120

# initial value for stack pointer
`define STACK_INIT $65000

######################## 
# INITIALIZATION CODE 
######################## 

  MOVW `STACK_INIT %SP    # init stack pointer

  # set board peripherals to 0
  MOVI $0 %rB
  MOVW `HEX_HIGH_ADDR %rA
  STOR %rB %rA
  MOVW `HEX_LOW_ADDR %rA 
  STOR %rB %rA
  MOVW `LEDS_ADDR %rA
  STOR %rB %rA

  CALL .reset_game     # reset game (set to initial state)
  BUC .game_pre_loop


######################## 
# MAIN LOOPS
########################

# -----------------------------------------------------
# listens for indicator to start game
.game_pre_loop
  MOVW `BTNS_ADDR %r0     # load buttons addr
  MOVW `LEDS_ADDR %r1
  MOVI $1 %rA 
  STOR %rA %r1
.__game_pre_loop
# check for start game 
  LOAD %r1 %r0    # get buttons
  ANDI $8 %r1     # get button 3
  CMPI $0 %r1
  BNE .__game_pre_loop    # loop again if button wasn't pressed
# start game
  CALL .start_game
  BUC .game_active_loop

# -----------------------------------------------------
# main loop for game, while active
.game_active_loop
# load necessary addresses
  MOVW `BTNS_ADDR %r0 
  MOVW `SW_ADDR %r1
  MOVW `MUSIC_STATE_ADDR %r5
  MOVW `CURRENT_WINDOW_ADDR %r6
  MOVW `DRUMPAD_COUNT_BASE_ADDR %r7
  MOVW `VGA_HCOUNT_ADDR %r8 
  MOVW `VGA_VCOUNT_ADDR %r9
  MOVW `VGA_VCOUNT_REFRESH_VAL %r4
  MOVW `LEDS_ADDR %r2
  MOVI $2 %rA 
  STOR %rA %r2
.__game_active_loop
# check if song is done 
  LOAD %r2 %r5
  CMPI $1 %r2
  BNE .__song_not_done
# song is done 
  CALL .end_game
  BUC .game_end_loop
.__song_not_done
# check for reset 
  LOAD %r2 %r0    # get buttons
  ANDI $2 %r2     # get button 1
  CMPI $0 %r2
  BNE .__game_active_check_for_pause    # button not pressed
  CALL .reset_game    
  BUC .game_pre_loop    # go to pre game loop
# check for pause
.__game_active_check_for_pause
  LOAD %r3 %r1    # get switches
  ANDI $1 %r3     # get first switch only
  CMPI $0 %r3  
  BEQ .__game_active_no_state_change    # pause not selected
  CALL .pause_game
  BUC .game_paused_loop   # go to paused loop
.__game_active_no_state_change
# process drumpad inputs
  CALL .drumpads_process_input
# synnchronize
  CALL .sync_update   # sync (return val in %rA)
  CMPI $1 %rA   # check if new window
  BNE .__check_vga  # skip to vga check if there was a new window
# if there was a new window
  LOAD %rB %r6            # load current window count
  SUBI $1 %rB             # subtract 1 because previous window is one being scored
  MOV %r7 %rA   # load base address to %rA
  CALL .update_score       # update score
  CALL .drumpads_clear    # clear drumpad input data structure
  CALL .write_score_to_hex    # show new score on hex
# check vga for queue to refresh
.__check_vga
  LOAD %rA %r9    # get vCount
  CMP %rA %r4     # compare to refresh val
  BNE .__skip_visual_refresh
# compare and refresh or skip
  CALL .vga_refresh
  MOVW `HEX_HIGH_ADDR %rA 
  LOAD %rB %rA
  ADDI $1 %rB 
  STOR %rB %rA
.__skip_visual_refresh
  BUC .__game_active_loop

# -----------------------------------------------------
# loop to check for unpause or reset while game is paused
.game_paused_loop
  MOVW `BTNS_ADDR %r0
  MOVW `SW_ADDR %r1
  MOVW `LEDS_ADDR %r2
  MOVI $4 %rA 
  STOR %rA %r2
.__game_paused_loop
# check for reset 
  LOAD %r2 %r0    # get buttons
  ANDI $2 %r2     # get button 1
  CMPI $0 %r2     # check if pressed
  BNE .__game_paused_check_for_unpause  # not pressed
  CALL .reset_game    
  BUC .game_pre_loop    # go to pre game loop
# check for unpause
.__game_paused_check_for_unpause
  LOAD %r3 %r1    # get switches
  ANDI $1 %r3     # get first switch only
  CMPI $0 %r3  
  BNE .__game_paused_loop
  CALL .unpause_game
  BUC .game_active_loop

# -----------------------------------------------------
# loop for when game has completed
# listen for restart indicator
.game_end_loop
  MOVW `BTNS_ADDR %r0
  MOVW `LEDS_ADDR %r1
  MOVI $8 %rA 
  STOR %rA %r1
.__game_end_loop
# check for reset
  LOAD %r2 %r0
  ANDI $2 %r2     # get button 1
  CMPI $0 %r2
  BNE .__game_end_loop      # if not pressed
  CALL .reset_game
  BUC .game_pre_loop


##############################
# GAME STATE CHANGE PROCEDURES
##############################

# resets game (go from any state to start)
.reset_game
# reset music/timer
  CALL .sync_reset
  CALL .sync_unpause    # make sure not paused
# enter freeplay mode
  CALL .disable_hps_stream
  CALL .reset_score
  CALL .vga_reset
  RET

# starts game (go from freeplay or end to game active)
.start_game 
# exit freeplay mode
  CALL .enable_hps_stream
  CALL .sync_reset  # reset 
  CALL .reset_score
  CALL .vga_reset
  RET

# pauses game (active to paused)
.pause_game
# pause music/timer
  CALL .sync_pause
  RET 

# unpauses game (paused to active)
.unpause_game
# unpause music/timer
  CALL .sync_unpause
  RET

# ends game (active to end)
.end_game 
# pause music/timer
  CALL .sync_pause
  CALL .vga_reset
  RET

########################### 
# GAME SCORE PROCEDURES
###########################

# update the current score by checking if 
# drumpad strike matches expected for current 
# window for each channel
# %rA: processed drumpad input base address
# %rB: number of window to check against
.update_score 
  SREG %r0 
  SREG %r1 
  MOVI $0 %r0     # drumpad count
  MOVI $0 %r1     # error count 
  MOVW `WINDOW_DATA_BASE_ADDR %rD
  LSHI $2 %rB       # multiply window count by 4 to get proper offset
  ADD %rD %rB       # add window base to offset to get address
.__update_score_loop
  LOAD %rC %rA    # load drumpad input
  LOAD %rD %rB    # load window data
  CMP %rC %rD     # compare expected to what was got
  BEQ .__update_score_no_error    # if match: there was no error
  ADDI $1 %r1       # if there was an error: increment error count
.__update_score_no_error
  CMPI $3 %r0     # check if checked final drumpad
  BEQ .__update_score_end
  ADDI $1 %r0       # increment drumpad count 
  ADDI $1 %rB       # go to next channel within window
  ADDI $1 %rA       # go to next drumapd input
  BUC .__update_score_loop
.__update_score_end
# update score 
  MOVW `GAME_SCORE_ADDR %rA
  LOAD %rB %rA    # load previous score 
  SUB %r1 %rB     # subtract error count from score
  STOR %rB %rA    # store new score
  LREG %r1 
  LREG %r0
  RET

# reset score to initial value
.reset_score
  MOVI `INIT_SCORE %rA
  MOVW `GAME_SCORE_ADDR %rB
  STOR %rA %rB
  RET

# write current score to hex
.write_score_to_hex
  MOVW `HEX_LOW_ADDR %rA
  MOVW `GAME_SCORE_ADDR %rB
  LOAD %rC %rB    # load score
  STOR %rC %rA    # store score to hex
  RET

############################
# SYNCHRONIZATION PROCEDURES
############################

# resets timer, resets music
.sync_reset
  MSCR    # reset counter
# reset music playback
  MOVW `MUSIC_CTRL_ADDR %rB
  LOAD %rD %rB    # load previous music_ctrl
  ORI $4 %rD      # set reset bit, don't change others
  STOR %rD %rB
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
  ANDI $11 %rD    # unset reset bit, don't change others
  STOR %rD %rB
  RET

# reads timer and updates the current time state of the game
# returns 1 if a new window has been reached
# returns 0 if a new window has not been reached
.sync_update 
  SREG %r0 
  SREG %r1
# if next window reached, update current window number
  MOVW `CURRENT_WINDOW_ADDR %rB 
  ADDI $2 %rB       # address of previous window start ms
  LOAD %rC %rB      # load previous window start ms
  MSCG %r0      # get current ms 
  MOV %r0 %r1   # move ms count
  SUB %rC %r1   # calculate window offset
  MOVW `WINDOW_LENGTH_MS %rA
  CMP %r1 %rA   # compare window offset to window length
  BLT .__sync_update_same_window    # if end of current window has not been reached
# if end of current window has been reached
# store new ms of next window start 
  STOR %r0 %rB
# set window offset to 0
  SUBI $1 %rB   # get address of window offset
  MOVI $0 %rA   # zero to indicate start of window
  STOR %rA %rB  # store zero
# increment window number
  SUBI $1 %rB   # get address of window number
  LOAD %rC %rB  # load old window number
  ADDI $1 %rC   # increment window number
  STOR %rC %rB  # store new window number
# set return value to 1 (to indicate new window reached)
  MOVI $1 %rA
  BUC .__sync_update_end
.__sync_update_same_window
  # set current window offset
  SUBI $1 %rB   # get address of current window offset
  STOR %r1 %rB    # store new window offset
  # return value 0 (to indicate new window not reached)
  MOVI $0 %rA
.__sync_update_end
  LREG %r1 
  LREG %r0
  RET

# pauses millisecond counter, pauses music
.sync_pause 
  MSCP $1   # pause millisecond counter
  MOVW `MUSIC_CTRL_ADDR %rB
  LOAD %rC %rB
  ORI $1 %rC
  STOR %rC %rB    # pause music
  RET

# unpause millicsecond counter, unpauses music
.sync_unpause
  MSCP $0     # unpause millisecond counter
  MOVW `MUSIC_CTRL_ADDR %rB
  LOAD %rC %rB
  ANDI $14 %rC
  STOR %rC %rB      # unpause music
  RET

############################## 
# GRAPHICS PROCEDURES 
##############################

.vga_reset 
# set colors to white
  MOVW `GRAPHICS_BASE_ADDR %r5 
  MOVI $7 %r8
  ADDI $2 %r5
  STOR %r8 %r5
  ADDI $3 %r5
  STOR %r8 %r5
  ADDI $3 %r5
  STOR %r8 %r5
  ADDI $3 %r5
  STOR %r8 %r5
# set initial block sizes
  MOVW `GRAPHICS_BASE_ADDR %r5 
  MOVI $0 %r6 
  MOVI $50 %r7
# chan 1
  STOR %r6 %r5
  ADDI $1 %r5
  STOR %r7 %r5
# chan 2
  ADDI $2 %r5
  STOR %r6 %r5
  ADDI $1 %r5
  STOR %r7 %r5
# chan. 3
  ADDI $2 %r5
  STOR %r6 %r5
  ADDI $1 %r5
  STOR %r7 %r5
# chan 4.
  ADDI $2 %r5
  STOR %r6 %r5
  ADDI $1 %r5
  STOR %r7 %r5
  RET

.vga_refresh
  SREG %r0 
  SREG %r1 
  SREG %r2

  MOVW `GRAPHICS_BASE_ADDR %rA
  LOAD %rB %rA  # y start
  ADDI $1 %rA
  LOAD %rC %rA  # y end

  MOVW $450 %rD # for comparision
  CMP %rC %rD   # compare end to end of screen
  BGT .__reset_block        # if off screen
# if not off screen:
  ADDI $1 %rC 
  ADDI $1 %rB
  BUC .__vga_refresh_write_new_pos
.__reset_block
  MOVI $0 %rB 
  MOVI $50 %rC
.__vga_refresh_write_new_pos
  STOR %rC %rA
  SUBI $1 %rA
  STOR %rB %rA
# wait until vga is in vertical retrace to return(this is not a permanent solution)
.__vga_refresh_wait_loop 
  MOVW `VGA_VCOUNT_ADDR %rA
  LOAD %rB %rA
  CMPI $0 %rB 
  BNE .__vga_refresh_wait_loop
  LREG %r2 
  LREG %r1 
  LREG %r0
  RET

############################## 
# MUSIC CTRL PROCEDURES
##############################

.enable_hps_stream 
  MOVW `MUSIC_CTRL_ADDR %rA
  LOAD %rC %rA    # load previous music_ctrl
  ORI $2 %rC      # store 1 in hps_en bit
  STOR %rC %rA
  RET 

.disable_hps_stream 
  MOVW `MUSIC_CTRL_ADDR %rA   
  LOAD %rC %rA    # load previous music_ctrl
  ANDI $13 %rC    # zero hps_en bit, don't change others
  STOR %rC %rA
  RET

############################## 
# DRUMPAD INPUT PROCEDURES
##############################

# process the input, keeps track of the number of times each pad was struck since last clear
.drumpads_process_input
# add space for caller saved registers that will be used
  SREG %r0
  SREG %r1 
  SREG %r2
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
  LSH %rB %rD     # shit by drumpad num so that val is 1 or 0
# load current value, add, and store back
  MOV %r0 %r1   # move base addr
  ADD %rB %r1   # calc address by adding offset to base addr
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
  LREG %r2
  LREG %r1 
  LREG %r0
  RET

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
  RET

# writes the drumpad data structure to the leds
.drumpads_write_to_leds
  MOVI $0 %rA   # drumpad count
  MOVI $0 %rC   # collecter
  MOVW `DRUMPAD_COUNT_BASE_ADDR %rD
.__drumpads_collect_data_loop
  LOAD %rB %rD      # load
  ADD %rB %rC     # collect
  CMPI $3 %rA   
  BEQ .__drumpads_write_to_leds # branch if processed drumpad three (most significant)
  ADDI $1 %rA   # add 1 to count
  ADDI $1 %rD   # add 1 to address
  BUC .__drumpads_collect_data_loop
.__drumpads_write_to_leds
  MOVW `LEDS_ADDR %rD  
  STOR %rC %rD    # store new data to leds
  RET

############################## 
# GENERAL PURPOSE PROCEDURES
##############################
