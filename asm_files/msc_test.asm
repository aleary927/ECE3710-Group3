# init stack pointer 
  LUI $255 %r15
  ORI $255 %r15
  SUBI $10 %r15   # make space for I/O

# load I/O addresses
# %r10 = switches 
# %r11 = leds 
# %r12 = hex low 
# %r13 = hex high
  LUI $255 %r0
  MOVI $254 %r10  # switches
  OR %r0 %r10 
  MOVI $253 %r11  # leds
  OR %r0 %r11
  MOVI $251 %r12  # hex low
  OR %r0 %r12
  MOVI $252 %r13  # hex high
  OR %r0 %r13

# turn all leds on 
  STOR %r0 %r11
# turn all hexs to 0 
  MOVI $0 %r1
  STOR %r1 %r12
  STOR %r1 %r13

# init counter 
  MSCP $1 # pause
  MSCR    # reset
  MSCP $0 # unpause

# init seconds count 
  MOVI $0 %r8
  MOVI $0 %r9 # ms on increment
# load 1000 
  LUI $3 %r5 
  ORI $232 %r5
# load 10'h3FF
  LUI $3 %r6
  ORI $255 %r6

# read from counter, update low hex with milliseconds
# keep track of seconds, put on high hex
.counter_loop 
  MSCG %r0    # get milliseconds 
  STOR %r0 %r12 # store to hex low
  CMP %r5 %r0 # check if matches 1000
  BNE .counter_loop # if haven't reached 1000: keep looping
  MSCR          # reset counter
  ADDI $1 %r8 
  STOR %r8 %r13
  BUC .counter_loop
# 1 second reached, reset counter
#.reset_counter
#  MSCR
#  BUC .counter_loop
  # CMP %r2 %r9 # compare agains ms on increment
  # BEQ .counter_loop # don't increment multiple times for same millisecond
  # ADDI $1 %r8
  # STOR %r8 %r13 # store to hex high
  # MOV %r2 %r9   # save new ms on increment
  # BUC .counter_loop

