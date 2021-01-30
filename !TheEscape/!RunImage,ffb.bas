
PROC_main
END

DEF PROC_main
  REM Current graphics buffer
  DIM SCR 0

  REM Player location
  LOCATIONX=0
  LOCATIONY=0

  REM Player ship attributes
  VELOCITY=0
  SHIELDS=100
  STRUCTURALINTEGRITY=100
  XPERCENT=5

  REM Used for centiseconds per frame calcs
  CENTS = TIME

  REM 800x600 GFX Area 1600x1200
  MODE 32

  REM Sprite set
  sprite_area% = FNload_sprites("Spr")

  REPEAT
    REM Store current time and last time
    LASTCENTS = CENTS
    CENTS = TIME

    REM Set grpahics buffer
    SYS "OS_Byte",112,SCR

     KEY = INKEY(0)

     IF KEY = 100 THEN
       LOCATIONX = LOCATIONX + (XPERCENT * (CENTS - LASTCENTS))
     ENDIF
     IF KEY = 97 THEN
       LOCATIONX = LOCATIONX - (XPERCENT * (CENTS - LASTCENTS))
     ENDIF

     CLS

     SYS "OS_SpriteOp",34+256,sprite_area%,"lcars",0,940,0


REM     PRINT "X:   " + STR$(LOCATIONX)
REM     IF KEY <> -1 THEN
REM     PRINT "Key: " + STR$(KEY)
REM     ELSE
REM     PRINT "Key:"
REM     ENDIF
REM     PRINT "CPF: " + STR$(CENTS - LASTCENTS)


     SYS "OS_SpriteOp",34+256,sprite_area%,"player_ship",LOCATIONX,0,0

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
     PRINT SHIELDS
     MOVE 130,1120
     PRINT STRUCTURALINTEGRITY
     MOVE 130,1090
     PRINT VELOCITY

     WAIT

     SYS "OS_Byte",113,SCR

     IF SCR=0 THEN SCR=1 ELSE SCR=0

  UNTIL FALSE

ENDPROC

DEF PROCdelay(n)
  T%=TIME+n:REPEAT UNTIL TIME > T%
ENDPROC

DEF FNload_sprites(sprite_file$)
  LOCAL length%, area_ptr%
  SYS "OS_File",13,sprite_file$ TO ,,,,length%
  DIM area_ptr% length%+4-1
  area_ptr%!0 = length%+4
  area_ptr%!4 = 16
  SYS "OS_SpriteOp",9+256,area_ptr%
  SYS "OS_SpriteOp",10+256,area_ptr%,sprite_file$
=area_ptr%



