# The procedures in this file handle syncronization of the game by updating a 
# global data structure which will contain the current window, and window offset.
# This effectively means that this code will track the progress through the song.
# 
# The procedures in this file are the only ones that should access the hardware 
# millisecond timer. This should help to keep code a bit easeir to debug.

`define WINDOW_LENGTH_MS 500

# resets the timer back to start
.sync_reset 

# reads timer and updates the current time state of the game
.sync_update 
  
  JAL %RA

# get the current window number
.__sync_get_window 

  JAL %RA

# get the current ms from start
.__sync_get_ms

  JAL %RA

# get pause state of game
.__sync_get_pause

  JAL %RA
