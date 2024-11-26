# Main file for initialization, and main loop.
# 
# Main loop will handling calling procedures that process I/O, 
# update game state, update visuals, and maintain syncronization.

`define STACK_TOP 65000

# init stack
  MOVW `STACK_TOP %r15

# setup initial game state

.main_loop

# process drumpad inputs 

# call to syncronization (determine if window has changed)

# game state update (if at end of window)

# write to HEX to indicate score

# read VGA hCount and vCount
# do visual refresh (if during vertical retrace)

  BUC .main_loop
