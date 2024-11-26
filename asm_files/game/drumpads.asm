# This file has procedures for directy dealing with the drumpad inputs. No 
# other code will directly access the drumpads.

# process the input, keeps track of the number of times each pad was struck since last clear
.drumpads_process_input

  JAL %RA

# clears the current inputs (resets each pad's count back to 0)
.drumpads_clear

  JAL %RA

