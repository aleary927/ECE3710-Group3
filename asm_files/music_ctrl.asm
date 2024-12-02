
# base address for current drumpad counts
`define DRUMPAD_COUNT_BASE_ADDR $4000
# number of drumpads
`define NUM_DRUMPADS $4

# base address for game state data structure
`define GAME_STATE_BASE_ADDR $5000

# syncroniaztion data structure
`define CURRENT_WINDOW_ADDR $6000

# value to load to music_ctrl to pause music
`define PAUSE_MUSIC $1
`define RESET_MUSIC $2

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



  MOVW $65000 %SP

  MOVW `SW_ADDR %r0
  MOVW `MUSIC_STATE_ADDR %r2
  MOVW `MUSIC_CTRL_ADDR %r8

# write no reset
.init
  CALL .write_no_reset

.main_loop 
# read from leds, store to music ctrl
  LOAD %r1 %r0
  STOR %r1 %r8

# determine if song is done
  LOAD %r3 %r2
  CMPI $1 %r3
  BEQ .__song_is_done

  BUC .main_loop

.__song_is_done
  MOVI $4 %rA
  CALL .write_reset
  BUC .main_loop


.write_pause
  MOVW `MUSIC_CTRL_ADDR %rC
  LOAD %rA %rC
  ORI $1 %rA
  STOR %rA %rC
  JUC %RA
.write_no_pause
  MOVW `MUSIC_CTRL_ADDR %rC
  LOAD %rA %rC
  ANDI $14 %rA
  STOR %rA %rC
  JUC %RA

.write_reset 
  MOVW `MUSIC_CTRL_ADDR %rC 
  LOAD %rA %rC 
  ORI $4 %rA 
  STOR %rA %rC 
  JUC %RA
.write_no_reset 
  MOVW `MUSIC_CTRL_ADDR %rC 
  LOAD %rA %rC 
  ANDI $11 %rA 
  STOR %rA %rC 
  JUC %RA
  

.write_hps_en
  MOVW `MUSIC_CTRL_ADDR %rC 
  LOAD %rA %rC 
  ORI $2 %rA 
  STOR %rA %rC 
  JUC %RA
.write_no_hps_en
  MOVW `MUSIC_CTRL_ADDR %rC 
  LOAD %rA %rC 
  ANDI $13 %rA 
  STOR %rA %rC 
  JUC %RA

