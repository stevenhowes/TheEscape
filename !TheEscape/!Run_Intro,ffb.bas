MODE 4
OFF
CLS

sprite_area% = FNload_sprites("Spr")

PROCdraw_sprite("intro_25",320,256)

SOUND ON
VOICES 4
VOICE 1,"WaveSynth-Beep"
VOICE 2,"WaveSynth-Beep"
VOICE 3,"WaveSynth-Beep"
VOICE 4,"WaveSynth-Beep"

SOUND 1,-10,189,200
SOUND 2,-10,141,200

SOUND 3,-10,169,200,200
SOUND 4,-10,121,200,200

SOUND 1,-10,133,200,400
SOUND 2,-10,181,200,400

SOUND 3,-10,149,200,600
SOUND 4,-10,101,200,600


SOUND 1,-10,93,200,825
SOUND 2,-10,141,200,825

SOUND 3,-10,73,200,1025

SOUND 4,-10,85,200,1225

SOUND 1,-10,53,200,1425

PROCdelay(1700)
PRINT "Press any key"

A = INKEY(1000)

END



REM Delay routine - thanks Sophie
DEF PROCdelay(n)
  T%=TIME+n:REPEAT UNTIL TIME > T%
ENDPROC

REM Shorthand for sprite drawing SWI
DEF PROCdraw_sprite(name$,x%,y%)
  SYS "OS_SpriteOp",34+256,sprite_area%,name$,x%,y%,8
ENDPROC

REM Loads sprite file - stolen off a forum somewhere
DEF FNload_sprites(sprite_file$)
  LOCAL length%, area_ptr%
  SYS "OS_File",13,sprite_file$ TO ,,,,length%
  DIM area_ptr% length%+4-1
  area_ptr%!0 = length%+4
  area_ptr%!4 = 16
  SYS "OS_SpriteOp",9+256,area_ptr%
  SYS "OS_SpriteOp",10+256,area_ptr%,sprite_file$
=area_ptr%
