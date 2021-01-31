SCREENMODE%=32
SCREENGFXWIDTH%=1600
SCREENGFXHEIGHT%=1200

PROC_main
END

DEF PROC_main
  REM Current graphics buffer
  DIM Scr% 0

  DIM PlayerLocation%(1)
  PlayerLocation%(0) = SCREENGFXWIDTH%/2
  PlayerLocation%(1) = 100
  PlayerVelocity%=0
  PlayerShields%=100
  PlayerStructuralIntegrity%=100

  DIM PlayerHitbox%(3)
  PlayerHitbox%() = 0,0,60,81

  DIM EnemyHitbox%(0,3)
  EnemyHitbox%() = 0,0,48,74

  XMovePerCent%=5
  ResetShipSprite% = 0

  MaxEnemies% = 4
  DIM EnemyLocations%(MaxEnemies% - 1,1)
  DIM EnemySprites$(MaxEnemies% - 1)
  DIM EnemyHitboxID%(MaxEnemies% - 1)

  REM Random it up for now
  FOR Enemy%=0 TO MaxEnemies% - 1
    EnemyLocations%(Enemy%,0) = RND(SCREENGFXWIDTH%)
    EnemyLocations%(Enemy%,1) = SCREENGFXHEIGHT% + (RND(SCREENGFXHEIGHT%/2) * (Enemy% + 1))
    EnemySprites$(Enemy%) = "durno_ship"
    EnemyHitboxID%(Enemy%) = 0
  NEXT Enemy%

  REM Show/hide debug display
  DebugOut%=0

  DIM SpecLocations%(1,49)
  FOR Spec%=0 TO 49
    SpecLocations%(0,Spec%) = RND(SCREENGFXWIDTH%)
    SpecLocations%(1,Spec%) = RND(SCREENGFXHEIGHT%)
  NEXT Spec%

  REM Used for centiseconds per frame calcs
  Cents% = TIME

  MODE SCREENMODE%

  REM Position text cursor at graphics location
  VDU 5

  REM Sprite set
  sprite_area% = FNload_sprites("Spr")

  REPEAT
    REM Store current time and last time
    LastCents% = Cents%
    Cents% = TIME

    REM Set grpahics buffer to one that's not in use
    SYS "OS_Byte",112,Scr%

    CLS

    REM Space dust / stars
    FOR Spec%=0 TO 49
      GCOL 0,0
      LINE SpecLocations%(0,Spec%),SpecLocations%(1,Spec%),SpecLocations%(0,Spec%),SpecLocations%(1,Spec%)
      SpecLocations%(1,Spec%) = SpecLocations%(1,Spec%) - ((Cents% - LastCents%) * PlayerVelocity%/10)
      IF SpecLocations%(1,Spec%) < 0 THEN
        SpecLocations%(1,Spec%) = SCREENGFXHEIGHT%
        SpecLocations%(0,Spec%) = RND(SCREENGFXWIDTH%)
      ENDIF
    NEXT Spec%

    REM Draw LCARS in top left
    PROCdraw_sprite("lcars",4,SCREENGFXHEIGHT%-180)

    REM If using l/r sprites we debounce to stop it looking twitchy
    IF Cents% > ResetShipSprite% THEN
      ShipSprite$ = "player_ship"
    ENDIF

    REM Handle Key inputs
    PROCinputs

    REM Attribute names
    GCOL 0,0
    MOVE 75,1150
    PRINT "Sheilds"
    MOVE 75,1120
    PRINT "Integrity"
    MOVE 75,1090
    PRINT "Velocity"

    REM Attribute values
    GCOL 0,7
    MOVE 130,1150
    PRINT PlayerShields%
    MOVE 130,1120
    PRINT PlayerStructuralIntegrity%
    MOVE 130,1090
    PRINT PlayerVelocity%

    REM Draw player ship
    PROCdraw_sprite(ShipSprite$,PlayerLocation%(0),PlayerLocation%(1))


    REM TODO: Only uses player velocity currently (/2 so they don't match stars)
    FOR Enemy%=0 TO MaxEnemies% - 1
      EnemyLocations%(Enemy%,1) = EnemyLocations%(Enemy%,1) - ((Cents% - LastCents%) * PlayerVelocity%/20)
      IF EnemyLocations%(Enemy%,1) < 0 THEN
        EnemyLocations%(Enemy%,1) = SCREENGFXHEIGHT% + RND(SCREENGFXHEIGHT%)
        EnemyLocations%(Enemy%,0) = RND(SCREENGFXWIDTH%)
      ENDIF
      PROCdraw_sprite(EnemySprites$(Enemy%),EnemyLocations%(Enemy%,0),EnemyLocations%(Enemy%,1))
    NEXT Enemy%

    IF DebugOut% = 1 THEN
      PROCdebugoutput
    ENDIF

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
  *FX 4
  IF INKEY(-122) THEN
    ShipSprite$ = "player_shipr"
    ResetShipSprite% = Cents% + 20
    PlayerLocation%(0) = PlayerLocation%(0) + (XMovePerCent% * (Cents% - LastCents%))
  ENDIF
  IF INKEY(-26) THEN
    ShipSprite$ = "player_shipl"
    ResetShipSprite% = Cents% + 20
    PlayerLocation%(0) = PlayerLocation%(0) - (XMovePerCent% * (Cents% - LastCents%))
  ENDIF
  IF INKEY(-58) THEN
     PlayerVelocity% = PlayerVelocity% + 1
     IF PlayerVelocity% > 100 THEN
       PlayerVelocity% = 100
     ENDIF
  ENDIF
  IF INKEY(-42) THEN
     PlayerVelocity% = PlayerVelocity% - 1
     IF PlayerVelocity% < 0 THEN
       PlayerVelocity% = 0
     ENDIF
  ENDIF
  IF INKEY(-17) THEN
      IF DebugOut% = 0 THEN DebugOut% = 1
  ENDIF
ENDPROC

REM Debug prints
DEF PROCdebugoutput
  MOVE 0,500
  PRINT "X:   " + STR$(PlayerLocation%(0)) " Y: " STR$(PlayerLocation%(1))
  PRINT "CPF: " + STR$(Cents% - LastCents%)

  FOR Enemy%=0 TO MaxEnemies% - 1
    PRINT "ENEMY:" STR$(Enemy%) + " " + STR$(EnemyLocations%(Enemy%,0)) + "," + STR$(EnemyLocations%(Enemy%,1))
  NEXT Enemy%


  FOR Enemy%=0 TO MaxEnemies% - 1
    RECT EnemyLocations%(Enemy%,0) + EnemyHitbox%(EnemyHitboxID%(Enemy%),0), EnemyLocations%(Enemy%,1) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1), EnemyHitbox%(EnemyHitboxID%(Enemy%),2), EnemyHitbox%(EnemyHitboxID%(Enemy%),3)
  NEXT Enemy%

  RECT PlayerLocation%(0) + PlayerHitbox%(0), PlayerLocation%(1) + PlayerHitbox%(1), PlayerHitbox%(2), PlayerHitbox%(3)
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



