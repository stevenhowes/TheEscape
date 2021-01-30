
PROC_main
END

DEF PROC_main
  REM Current graphics buffer
  DIM Scr% 0

  DIM PlayerLocation%(1)
  PlayerLocation%(0) = 800
  PlayerLocation%(1) = 100
  PlayerVelocity%=0
  PlayerShields%=100
  PlayerStructuralIntegrity%=100
  XMovePerCent%=5

  REM Show/hide debug display
  DebugOut%=0

  REM Used for centiseconds per frame calcs
  Cents% = TIME

  REM 800x600x256 GFX Area 1600x1200
  MODE 32

  REM Sprite set
  sprite_area% = FNload_sprites("Spr")

  REPEAT
    REM Store current time and last time
    LastCents% = Cents%
    Cents% = TIME

    REM Set grpahics buffer to one that's not in use
    SYS "OS_Byte",112,Scr%



    CLS

    REM Draw LCARS in top left
    PROCdraw_sprite("lcars",0,940)

    IF DebugOut% = 1 THEN
      PROCdebugoutput
    ENDIF

    REM Handle Key inputs
    PROCinputs

    REM Use graphics cursor for text (TODO: Is this needed in loop?_)
    VDU 5

    GCOL 0,0
    MOVE 75,1150
    PRINT "Sheilds"
    MOVE 75,1120
    PRINT "Integrity"
    MOVE 75,1090
    PRINT "Velocity"

    GCOL 0,7
    MOVE 130,1150
    PRINT PlayerShields%
    MOVE 130,1120
    PRINT PlayerStructuralIntegrity%
    MOVE 130,1090
    PRINT PlayerVelocity%

    REM Draw player ship
    PROCdraw_sprite("player_ship",PlayerLocation%(0),PlayerLocation%(1))

    REM Wait for rendering to complete
    WAIT

    REM Display edited buffer
    SYS "OS_Byte",113,Scr%

    REM Switch draw buffer
    IF Scr%=0 THEN Scr%=1 ELSE Scr%=0

  UNTIL FALSE

ENDPROC

REM Input handling
DEF PROCinputs
  REM TODO: Scan individual keys so we can handle specials (e.g. arrows)
  KEY = INKEY(0)

  IF KEY = 100 THEN
    PlayerLocation%(0) = PlayerLocation%(0) + (XMovePerCent% * (Cents% - LastCents%))
  ENDIF
  IF KEY = 97 THEN
    PlayerLocation%(0) = PlayerLocation%(0) - (XMovePerCent% * (Cents% - LastCents%))
  ENDIF
  IF KEY = 113 THEN
      IF DebugOut% = 1 THEN DebugOut% = 0 ELSE DebugOut% = 1
  ENDIF
ENDPROC

REM Debug prints
DEF PROCdebugoutput
  MOVE 0,500
  PRINT "X:   " + STR$(PlayerLocation%(0)) " Y: " STR$(PlayerLocation%(1))
  IF KEY <> -1 THEN
    PRINT "Key: " + STR$(KEY)
  ELSE
    PRINT "Key:"
  ENDIF
  PRINT "CPF: " + STR$(Cents% - LastCents%)
ENDPROC

REM Delay routine - thanks Sophie
DEF PROCdelay(n)
  T%=TIME+n:REPEAT UNTIL TIME > T%
ENDPROC

REM Shorthand for sprite drawing SWI
DEF PROCdraw_sprite(name$,x%,y%)
  SYS "OS_SpriteOp",34+256,sprite_area%,name$,x%,y%,0
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



