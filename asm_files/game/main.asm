# Main file for initialization, and main loop.
# 
# Main loop will handling calling procedures that process I/O, 
# update game state, update visuals, and maintain syncronization.

# initial value for stack
`define STACK_INIT 65500

# init stack
  MOVW `STACK_INIT %SP

# setup initial game state

.main_loop

# process drumpad inputs 

# call to syncronization (determine if window has changed)

# game state update (if at end of window)

# write to HEX to indicate score

# read VGA hCount and vCount
# do visual refresh (if during vertical retrace)

  BUC .main_loop
