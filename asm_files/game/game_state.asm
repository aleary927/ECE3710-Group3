# The procedures in this file are responsible for keeping track of the score of the 
# game. Game scores are updated by processing inputs at the end of each window. This 
# involves reading from the drumpad input data structure.
# 
# These procedures will update a global data structure, allowing code that writes to I/O, etc. 
# to access these values.


# initialize/reset the game state  (score to default value)
.game_state_init 

  JAL %RA

# update the game state, this should be called at the end of a window
.game_state_update 

  JAL %RA
