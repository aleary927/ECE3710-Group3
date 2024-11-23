# Software 

## Note Data structure 
* segment of data will follow code, representing note locations within the music
* data needs to be in such a way that it is clear whether there is a note in the current time frame
* song will be split into fixed-length windows 
    * a window will indicate which channels (of the 4 drumpad) have a note in that window

## Timing and Syncronization 
* Consider the song as split into windows (likely half seconds / 500ms)
* Each window of the song will have an expected value (0 or 1) for each of the four channels 
* There will be a data structre that is updated so that there is a stable value indicating if a note has been hit 
within the current window 
    * this data structure will be cleared at the start of the next segment
    * this data structure will be updated in the main loop, because of the need to detect inputs at a latency far 
    lower than the window size

## General Layout 
* First code will initialize the stack, and load default values into all I/O peripherals 
* main loop follows initialization, listens for events from peripherals 
    * VGA vertical retrace: initiates refresh of display 
    * drumpad inputs: updates input data structure
    * end of current window: clears input data structure
    * game state update (score, pauses, resets) has to be worked into this


## Visual refresh 
* screen will always have a time associated with it 
    * the bottom of the screen is the current time
    * the top of the screen is the current time plus some reasnable amount (maybe 2 seconds)
    * note that windows will usually not align perfectly on the time bounds of the screen, meaning 
    that blocks (notes) on the screen will often be partly in view but not fully
* considers a few windows, probably current and a few after it
    * this corresponds to the time difference between the top and bottom of the screen 
* each window currently in view has a current location on the screen, so this has to be used to update note locations
    * since notes will be aligned a fixed window size, have to calculate location of oldest window within view, 
    and each successive note will be a fixed offset (really a multiple of the window length) from this location
* there will be some visual indication of inputs 
    * could be the current window (block in channel corresponding to input) changing color 
    * another option would be to change color in block at bottom of screen (separate from windows)
* additional visual elements (after simplest implementation is completed)
    * animation for strikes 
        * changing block size 
        * special color to indicate incorrect inputs 
    * indication of score on screen 
    * indication of current time in song on screen 
        * also could have indication of progress through song (maybe a progress bar)
    * pause status indication on screen 
    * special start and end screen

## Drumpad Inputs 
* will listen for drumpad inputs in the main loop 
* each time that a drumpad is struck, the input data structure will reflect that strike for the rest of the current window
* the inputs are cleared at the bounds of windows 

## Game State Tracking 
* either subtractive or additive score 
* subtractive: 
    * score starts at 100 (or other arbitrary score)
    * incorrect inputs will subtract from score 
        * missed a note 
        * played note at wrong time 
    * perfect score would be to keep original value
* additive:
    * score starts at 0 
    * add to score for each successful note 
    * subtract for each incorrect input 
    * negative score possible 
    * perfect score depends on number of notes in song

