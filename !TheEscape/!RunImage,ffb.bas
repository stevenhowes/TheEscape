SCREENMODE%=32
SCREENGFXWIDTH%=1600
SCREENGFXHEIGHT%=1200

PROC_main
END

DEF PROC_main
  REM Current graphics buffer
  Scr% = 1

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

  MaxEnemies% = 10
  DIM EnemyLocations%(MaxEnemies% - 1,1)
  DIM EnemySprites$(MaxEnemies% - 1)
  DIM EnemyHitboxID%(MaxEnemies% - 1)
  DIM EnemyVelocityX%(MaxEnemies% - 1)
  DIM EnemyVelocityY%(MaxEnemies% - 1)

  REM Random it up for now
  FOR Enemy%=0 TO MaxEnemies% - 1
    EnemyLocations%(Enemy%,0) = RND(SCREENGFXWIDTH%)
    EnemyLocations%(Enemy%,1) = SCREENGFXHEIGHT% + (RND(SCREENGFXHEIGHT%/2) * (Enemy% + 1))
    EnemySprites$(Enemy%) = "durno_ship"
    EnemyVelocityX%(Enemy%) = RND(10) - 5
    EnemyVelocityY%(Enemy%) = RND(5) + 5
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

    REM Controls
    PROCinputs

    REM NPCs
    PROCenemy_ship_move
    PROCenemy_ship_collide_player
    PROCenemy_ship_collide_npc

    REM Still not sure about this bollocks, but it does seem to work now
    SYS "OS_Byte",19
    SYS "OS_Byte",114,1
    SYS "OS_Byte",113,Scr%
    Scr% = Scr% + 1
    IF Scr% > 3 THEN Scr% = 1
    SYS "OS_Byte",112,Scr%

    CLS

    REM Environment
    PROCspacedust_draw

    REM Player
    PROCplayer_ship_draw

    PROCenemy_ship_draw

    REM UI
    PROChud_draw

    IF DebugOut% = 1 THEN
      PROCdebugoutput
    ENDIF

  UNTIL FALSE

ENDPROC

DEF PROCspacedust_draw
  REM Space dust / stars
  FOR Spec%=0 TO 49
    GCOL 0,0
    LINE SpecLocations%(0,Spec%),SpecLocations%(1,Spec%),SpecLocations%(0,Spec%),(PlayerVelocity% / 3) + SpecLocations%(1,Spec%)
    SpecLocations%(1,Spec%) = SpecLocations%(1,Spec%) - ((Cents% - LastCents%) * PlayerVelocity%/10)
    IF SpecLocations%(1,Spec%) < 0 THEN
      SpecLocations%(1,Spec%) = SCREENGFXHEIGHT%
      SpecLocations%(0,Spec%) = RND(SCREENGFXWIDTH%)
    ENDIF
  NEXT Spec%
ENDPROC

REM Move enemy ship (display and physical)
DEF PROCenemy_ship_move
  REM TODO: Only uses player velocity currently (/2 so they don't match stars)
  FOR Enemy%=0 TO MaxEnemies% - 1
    EnemyLocations%(Enemy%,1) = EnemyLocations%(Enemy%,1) - ((Cents% - LastCents%) * PlayerVelocity%/20) - ((Cents% - LastCents%) * EnemyVelocityY%(Enemy%))

    EnemyLocations%(Enemy%,0) = EnemyLocations%(Enemy%,0) - ((Cents% - LastCents%) * EnemyVelocityX%(Enemy%))

    IF EnemyLocations%(Enemy%,1) <= 0 THEN
      EnemyLocations%(Enemy%,1) = SCREENGFXHEIGHT% + RND(SCREENGFXHEIGHT%)
      EnemyLocations%(Enemy%,0) = RND(SCREENGFXWIDTH%)
    ENDIF
  NEXT Enemy%
ENDPROC

REM Hud drawing (sprites and real-time)
DEF PROChud_draw
  REM Draw LCARS in top left
  PROCdraw_sprite("lcars",4,SCREENGFXHEIGHT%-180)

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
ENDPROC

DEF PROCenemy_ship_collide_npc
  FOR Enemy%=0 TO MaxEnemies% - 1
   CollidesWith% = Enemy%

    REM This is our hitbox
    x1 = EnemyLocations%(Enemy%,0) + EnemyHitbox%(EnemyHitboxID%(Enemy%),0)
    y1 = EnemyLocations%(Enemy%,1) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1)
    w1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),2)
    h1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),3)

    FOR OtherEnemy%=0 TO MaxEnemies% - 1
      REM Collision with an enemy
      IF Enemy% > OtherEnemy% THEN
        x2 = EnemyLocations%(OtherEnemy%,0) + EnemyHitbox%(EnemyHitboxID%(OtherEnemy%),0)
        y2 = EnemyLocations%(OtherEnemy%,1) + EnemyHitbox%(EnemyHitboxID%(OtherEnemy%),1)
        w2 = EnemyHitbox%(EnemyHitboxID%(OtherEnemy%),2)
        h2 = EnemyHitbox%(EnemyHitboxID%(OtherEnemy%),3)
        IF FNcollide(x1, y1, w1, h1, x2, y2, w2, h2) = 1 THEN
          CollidesWith% = OtherEnemy%
          MOVE x2+h2,y2+w2
          PRINT STR$(CollidesWith%) + " hits " + STR$(Enemy%)
        ENDIF
      ENDIF
    NEXT OtherEnemy%
  NEXT Enemy%
ENDPROC

REM Handle enemy collisions with anything
DEF PROCenemy_ship_collide_player
  FOR Enemy%=0 TO MaxEnemies% - 1

    REM This is our hitbox
    x1 = EnemyLocations%(Enemy%,0) + EnemyHitbox%(EnemyHitboxID%(Enemy%),0)
    y1 = EnemyLocations%(Enemy%,1) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1)
    w1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),2)
    h1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),3)

    REM Collision with a player
    x2 = PlayerLocation%(0) + PlayerHitbox%(0)
    y2 = PlayerLocation%(1) + PlayerHitbox%(1)
    w2 = PlayerHitbox%(2)
    h2 = PlayerHitbox%(3)
    IF FNcollide(x1, y1, w1, h1, x2, y2, w2, h2) = 1 THEN
      MOVE x1+w1,y1+h1
      PlayerVelocity% = 0
      PRINT "BOOM"
      REM IF DebugOut% = 1 THEN
      REM  PRINT " hits player"
      REM ENDIF
    ENDIF
  NEXT Enemy%
ENDPROC

DEF FNcollide(x1,y1,w1,h1,x2,y2,w2,h2)
  collide% = 0
    IF (x1 + w1) >= x2 THEN
      IF x1 <= (x2 + w2) THEN
        IF (y1 + h1) >= y2 THEN
          IF y1 <= (y2 + h2) THEN
            collide% = 1
          ENDIF
        ENDIF
      ENDIF
    ENDIF
=collide%

REM Draw enemy ships
DEFPROCenemy_ship_draw
  REM TODO: Only uses player velocity currently (/2 so they don't match stars)
  FOR Enemy%=0 TO MaxEnemies% - 1
    PROCdraw_sprite(EnemySprites$(Enemy%),EnemyLocations%(Enemy%,0),EnemyLocations%(Enemy%,1))
  NEXT Enemy%
ENDPROC

REM Draw player ship
DEF PROCplayer_ship_draw
  REM If using l/r sprites we debounce to stop it looking twitchy
  IF Cents% > ResetShipSprite% THEN
    ShipSprite$ = "player_ship"
  ENDIF
  PROCdraw_sprite(ShipSprite$,PlayerLocation%(0),PlayerLocation%(1))
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
  PRINT "Scr: " + STR$(Scr%)

  FOR Enemy%=0 TO MaxEnemies% - 1
    PRINT "ENEMY:" STR$(Enemy%) + " " + STR$(EnemyLocations%(Enemy%,0)) + "," + STR$(EnemyLocations%(Enemy%,1)) + " " + STR$(EnemyVelocityX%(Enemy%)) + " " + STR$(EnemyVelocityY%(Enemy%))
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
