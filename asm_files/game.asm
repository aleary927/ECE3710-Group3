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

`define GRAPHICS_BASE_ADDR $65250

# syncroniztion data structure
`define CURRENT_WINDOW_ADDR $30000

`define WINDOW_DATA_BASE_ADDR $5000

# sum of vcount and hcount to trigger refresh
`define VGA_VCOUNT_REFRESH_VAL $479
`define TILE_LENGTH $125

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
`define WINDOW_LENGTH_MS $500

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

######################## 
# MAIN LOOP
########################

# main loop
.main_loop 
  CALL .reset_game     # reset game (set to initial state)
# wait on indicator to start game 
  CALL .listen_for_start
# start game
  CALL .start_game 
# enter main game logic
  CALL .main_game_logic   # return value indicates if reset or end reached
  CMPI $0 %rA 
  BEQ .main_loop    # returned 0 if reset, go to loop start
# game not reset, end game
  CALL .end_game
# wait for game to be reset
  CALL .listen_for_reset
  BUC .main_loop

# -----------------------------------------------------
# main loop for game, while active
# **ignoring caller-callee conventions because loop above this 
# doesn't store anything in registers**
# return 0 if game reset, 1 if game ended
.main_game_logic
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
# song is done, return 1
  MOVI $1 %rA
  RET
.__song_not_done
# check for reset 
  LOAD %r2 %r0    # get buttons
  ANDI $2 %r2     # get button 1
  CMPI $0 %r2
  BNE .__game_active_check_for_pause    # button not pressed
  MOVI $0 %rA
  RET     # reset, return 0
# check for pause
.__game_active_check_for_pause
  LOAD %r3 %r1    # get switches
  ANDI $1 %r3     # get first switch only
  CMPI $0 %r3  
  BEQ .__game_active_update_logic   # pause not selected
# pause selected, pause game
  CALL .pause_game         
  CALL .listen_for_unpause_or_reset   # wait for unpause or reset
  CMPI $0 %rA   
  BNE .__game_active_game_unpaused
# game reset
  RET     # 0 alrady in %rA, indicating reset
.__game_active_game_unpaused
  CALL .unpause_game
.__game_active_update_logic
# process drumpad inputs
  CALL .drumpads_process_input
# synchronize
  CALL .sync_update   # sync (return val in %rA)
  CMPI $1 %rA   # check if new window
  BNE .__check_vga  # skip to vga check if there was not a new window
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

############################# 
# LISTENERS
#############################

# -----------------------------------------------------
# listens for indicator to start game
.listen_for_start
  MOVW `BTNS_ADDR %rA     # load buttons addr
.__listen_for_start_loop
# check for start game 
  LOAD %rB %rA    # get buttons
  ANDI $8 %rB     # get button 3
  CMPI $0 %rB
  BNE .__listen_for_start_loop    # loop again if button wasn't pressed
  RET 

# -----------------------------------------------------
# loop to check for unpause or reset while game is paused
# returns 0 for reset, 1 for unpaused
.listen_for_unpause_or_reset
  MOVW `BTNS_ADDR %rA
  MOVW `SW_ADDR %rB
.__listen_for_unpause_or_reset_loop
# check for reset 
  LOAD %rC %rA    # get buttons
  ANDI $2 %rC     # get button 1
  CMPI $0 %rC     # check if pressed
  BNE .__listen_for_unpause_or_reset_check_for_unpause
  MOVI $0 %rA     # 0 indicates reset
  RET
# check for unpause
.__listen_for_unpause_or_reset_check_for_unpause
  LOAD %rC %rB    # get switches
  ANDI $1 %rC     # get first switch only
  CMPI $0 %rC     # check if unset
  BNE .__listen_for_unpause_or_reset_loop
  MOVI $1 %rA     # 1 indicates unpaused
  RET

# -----------------------------------------------------
# listen for reset indicator
.listen_for_reset
  MOVW `BTNS_ADDR %rA
.__listen_for_reset_loop
# check for reset
  LOAD %rB %rA
  ANDI $2 %rB     # get button 1
  CMPI $0 %rB
  BNE .__listen_for_reset_loop
  RET

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
  MOVW `LEDS_ADDR %rA 
  MOVI $1 %rB 
  STOR %rB %rA
  RET

# starts game (go from freeplay to game active)
.start_game 
# exit freeplay mode
  CALL .enable_hps_stream
  CALL .sync_reset  # reset 
  CALL .reset_score
  CALL .vga_reset
  MOVW `LEDS_ADDR %rA 
  MOVI $2 %rB 
  STOR %rB %rA
  RET

# pauses game (active to paused)
.pause_game
# pause music/timer
  CALL .sync_pause
  MOVW `LEDS_ADDR %rA 
  MOVI $4 %rB 
  STOR %rB %rA
  RET 

# unpauses game (paused to active)
.unpause_game
# unpause music/timer
  CALL .sync_unpause
  MOVW `LEDS_ADDR %rA 
  MOVI $2 %rB 
  STOR %rB %rA
  RET

# ends game (active to end)
.end_game 
# pause music/timer
  CALL .sync_pause
  CALL .vga_reset
  MOVW `LEDS_ADDR %rA 
  MOVI $8 %rB 
  STOR %rB %rA
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
# spin for a while to make sure HPS recieves reset signal
  MOVW $1000 %rA
  MOVI $0 %rC
.__sync_reset_spin 
  ADDI $1 %rC
  CMP %rC %rA
  BLT .__sync_reset_spin
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
  SREG %r7    # window count
  SREG %r8    # lane count
  SREG %r9
  MOVI $0 %r7   # window count 0 
# outer loop for notes/windows 
.__vga_reset_window_loop
  MOVI $0 %r8     # lane count 0
# inner loop for lanes
.__vga_reset_lane_loop
# move all values into place
  MOV %r7 %rA   # window 
  MOV %r8 %r9   # lane
  MOVI $0 %rB   # top
  MOVW $0 %rC   # bottom
  MOVI $0 %rD   # color
  CALL ._visual_update_set_tile
  CMPI $3 %r8   # check agains max lane count
  BEQ .__vga_reset_window_done
  ADDI $1 %r8   # next lane
  BUC .__vga_reset_lane_loop
# after updating lanes
.__vga_reset_window_done
  CMPI $3 %r7   # check against max window count
  BEQ .__vga_reset_done
  ADDI $1 %r7     # next window
  BUC .__vga_reset_window_loop
.__vga_reset_done
  LREG %r9
  LREG %r8
  LREG %r7
  RET

# each pixel corresponds to 4 milliseconds
# vertical column corresponds to a bit over 4000 milliseconds
.vga_refresh 
  SREG %r0  # pointer to window data
  SREG %r1  
  SREG %r2  
  SREG %r3  # length of a tile
  SREG %r4 
  SREG %r5
  SREG %r6 
  SREG %r7
  SREG %r8
  SREG %r9
  MOVW `WINDOW_DATA_BASE_ADDR %r0
  MOVW `TILE_LENGTH %r3
  MOVW `CURRENT_WINDOW_ADDR %r1
  LOAD %r6 %r1    # load current window
  MOV %r6 %rB
  LSHI $2 %rB     # multiply by four to get offset to current window offset
  ADD %rB %r0     # add offset to base address to get pointer to current window data
  
  ADDI $1 %r1     # calc address for ms offset into window
  LOAD %rC %r1    # load ms offset into window
  MOVW $400 %r2   # load ms per tile
  SUB %rC %r2     # subtract ms offset from ms per tile to get ms remaining in tile
# find dimensions of current tile, bottom of display is always start of first tile
# end of first tile offset from display end is number of ms remaining in block divided by ms per pixel
# (4 is the ms per pixel) (divide by 4 by doing right shift by 2) 
# find offset from bottom (in pixels)
  LSHI $-2 %r2
# subtract offset from bottom to get first top position
  MOVW $450 %r5   # bottom position
  SUB %r2 %r5     # subtract offset from bottom position to get top position
# determine if drumpad has been struck, and update color accordingly
  MOVW `DRUMPAD_COUNT_BASE_ADDR %r8 
  ADDI $3 %r8     # get address of last drumpad 
  MOVI $3 %r4     # load 3 for drumpad num
# loop to update first row of tiles, checking drum pad status on each in order to select a color
.__visual_update_drumpad_loop
# check if drumpad hit or not
  LOAD %r7 %r8
  CMPI $0 %r7 
  BEQ .__drumpad_not_hit
  MOVI $4 %rD   # set color red
  BUC .__visual_update_drumpad_loop_set_tile
# drumpad not hit, tile color depends on if it is a note or not
.__drumpad_not_hit
  MOV %r6 %rA
  MOV %r4 %rB
  CALL .check_if_note_exists
  CMPI $0 %rA
  BNE .__visual_update_drumpad_loop_note_exists   # if note exists
  MOVI $0 %rD     # color black for no note
  BUC .__visual_update_drumpad_loop_set_tile
.__visual_update_drumpad_loop_note_exists 
  MOVI $7 %rD     # color white for note 
.__visual_update_drumpad_loop_set_tile
  MOV %r4 %r9   # move drumpad/lane number
  MOVI $0  %rA    # move window number
  MOV %r5  %rB     # move tile start position
  MOVW $450 %rC   # move tile end position
  CALL ._visual_update_set_tile   # update tile

  CMPI $0 %r4
  BEQ .__visual_update_first_row_done   # if last drumpad processed
  SUBI $1 %r8        # next drumpad address 
  SUBI $1 %r4         # next drumpad num (lane num)
  BUC .__visual_update_drumpad_loop

.__visual_update_first_row_done
# loop through next 3 tiles (just have to subtract tile length to get positions)
  MOVI $1 %r8      # count of windows/tiles, from 1 through 3
  ADDI $1 %r6     # increment window number
# nested loops for next tiles and lanes
.__visual_update_window_loop
# subtract tile length to get bounds of each tile
  MOV %r5 %r1   # move previous tile top
  SUBI $1 %r1   # sub 1 from last tile end to get new tile bottom
  SUB %r3 %r5   # subtract tile length from last tile top to get new top
  CMPI $0 %r5   # compare top to 0
  BLE .__visual_update_window_in_bounds
  MOVI $0 %r5   # if not in bounds, set top to be 0
.__visual_update_window_in_bounds
  MOVI $0 %r4      # count of lanes, from 0 through 3
# subloop for going through lanes of window
.__visual_update_lanes_subloop
# check if there is a note here
  MOV %r6 %rA 
  MOV %r4 %rB
  CALL .check_if_note_exists
  CMPI $0 %rA
  BNE .__visual_update_window_loop_note_exists   # if note exists
  MOVI $0 %rD     # color black for no note
  BUC .__visual_update_window_loop_set_tile
.__visual_update_window_loop_note_exists 
  MOVI $7 %rD     # color white for note 
.__visual_update_window_loop_set_tile
  MOV %r4 %r9 
  MOV %r8 %rA
  MOV %r5 %rB
  MOV %r1 %rC
  CALL ._visual_update_set_tile   # update tile
  CMPI $3 %r4
  BEQ .__visual_update_lanes_done
  ADDI $1 %r4
  BUC .__visual_update_lanes_subloop

.__visual_update_lanes_done
  CMPI $3 %r8    # check if last window done
  BEQ   .__visual_update_end
  ADDI $1 %r8   # increment tile/window count
  ADDI $1 %r6     # increment window number
  BUC .__visual_update_window_loop

.__visual_update_end
  LREG %r9
  LREG %r8
  LREG %r7 
  LREG %r6 
  LREG %r5 
  LREG %r4
  LREG %r3
  LREG %r2
  LREG %r1
  LREG %r0
  RET

# %rA: window number
# %rB: drumpad number
.check_if_note_exists
  MOVW `WINDOW_DATA_BASE_ADDR %rC
  LSHI $2 %rA     # multiply by four to get offset
  ADD %rA %rC     # add offset to get to proper window
  ADD %rB %rC     # add drumpad num
  LOAD %rA %rC
  CMPI $0 %rA     
  BEQ .__check_if_note_exists_no_note 
  MOVI $1 %rA   # 1 indicates note exists
  BUC .__check_if_note_exists_end
  .__check_if_note_exists_no_note
  MOVI $0 %rA   # zero for no note
  .__check_if_note_exists_end
  RET

# update a tile 
# %r9: lane number
# %rA: tile number
# %rB: y pos 1 (top)
# %rC: y pos 2 (bottom)
# %rD: color
._visual_update_set_tile
  SREG %r0
# load graphics address
  MOVW `GRAPHICS_BASE_ADDR %r0
# calculate address (for y pos 1)
  LSHI $3 %r9   # multiply lane number by 8
  LSHI $1 %rA   # multiply tile number by 2
  ADD %r9 %r0   # add offset offset
  ADD %rA %r0   # add tile offset
# combine color with y pos 1
  LSHI $13 %rD    # shift to align 3-bit color high 
  OR %rD %rB
# write 
  STOR %rB %r0
  ADDI $1 %r0   # add one to address to get y pos 2
  STOR %rC %r0
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
