SCREENMODE%=32
SCREENGFXWIDTH%=1600
SCREENGFXHEIGHT%=1200
MaxEnemies% = 10
PlayerYHeightDivide%=8

IF INKEY(-42) THEN
  SCREENMODE%=28
  SCREENGFXWIDTH%=1280
  SCREENGFXHEIGHT%=960
  MaxEnemies% = 5
  PlayerYHeightDivide%=6
ENDIF

X = 0
Y = 1

PROC_main
END

DEF PROC_main
  REM Current graphics buffer
  Scr% = 1

  DIM PlayerLocation%(1)
  PlayerLocation%(X) = SCREENGFXWIDTH%/2
  PlayerLocation%(Y) = SCREENGFXHEIGHT%/PlayerYHeightDivide%
  PlayerVelocity%=0
  PlayerShields%=100
  PlayerStructuralIntegrity%=100

  DIM PlayerHitbox%(3)
  PlayerHitbox%() = 0,0,60,81

  DIM PlayerPhaserOffset%(1,1)
  PlayerPhaserOffset%(0,X) = 20
  PlayerPhaserOffset%(0,Y) = 75
  PlayerPhaserOffset%(1,X) = 40
  PlayerPhaserOffset%(1,Y) = 75

  LeftID% = -1
  RightID% = -1

  DIM EnemyHitbox%(1,3)
  EnemyHitbox%(0,0) = 0
  EnemyHitbox%(0,1) = 0
  EnemyHitbox%(0,2) = 48
  EnemyHitbox%(0,3) = 74
  EnemyHitbox%(1,0) = 0
  EnemyHitbox%(1,1) = 0
  EnemyHitbox%(1,2) = 38
  EnemyHitbox%(1,3) = 56

  XMovePerCent%=5
  ResetShipSprite% = 0

  DIM EnemyLocations%(MaxEnemies% - 1,1)
  DIM EnemySprites$(MaxEnemies% - 1)
  DIM EnemyHitboxID%(MaxEnemies% - 1)
  DIM EnemyVelocity%(MaxEnemies% - 1,1)
  DIM EnemyHealth%(MaxEnemies% - 1)
  DIM EnemyCollidable%(MaxEnemies% -1)
  DIM EnemyCollideForce%(MaxEnemies% -1)

  REM Random it up for now
  FOR Enemy%=0 TO MaxEnemies% - 1
    PROCrespawn_enemy(Enemy%)
  NEXT Enemy%

  REM Show/hide debug display
  DebugOut%=0

  DIM SpeckLocations%(49,1)
  FOR Speck%=0 TO 49
    SpeckLocations%(Speck%,X) = RND(SCREENGFXWIDTH%)
    SpeckLocations%(Speck%,Y) = RND(SCREENGFXHEIGHT%)
  NEXT Speck%

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
    REM PROCenemy_ship_collide_npc
    PROCplayer_arc_calculatetarget
    PROCenemy_ship_handle_damage

    REM Still not sure about this bollocks, but it does seem to work now
    SYS "OS_Byte",19
    SYS "OS_Byte",114,1
    SYS "OS_Byte",113,Scr%
    Scr% = Scr% + 1
    IF Scr% > 3 THEN Scr% = 1
    SYS "OS_Byte",112,Scr%

    CLS

    REM Environment
    PROCspecks_draw

    REM Player
    PROCplayer_ship_draw
    PROCplayer_target_draw

    PROCenemy_ship_draw

    REM UI
    PROChud_draw

    IF DebugOut% = 1 THEN
      PROCdebugoutput
    ENDIF

  UNTIL FALSE

ENDPROC

DEF PROCenemy_ship_handle_damage
ENDPROC

DEF PROCrespawn_enemy(Enemy%)
    EnemyLocations%(Enemy%,X) = RND(SCREENGFXWIDTH%)
    EnemyLocations%(Enemy%,Y) = SCREENGFXHEIGHT% + (RND(SCREENGFXHEIGHT%/2) * (Enemy% + 1))
    EnemySprites$(Enemy%) = "durno_ship"
    EnemyVelocity%(Enemy%,X) = 0
    EnemyVelocity%(Enemy%,Y) = RND(3) + 2
    EnemyHitboxID%(Enemy%) = RND(2)-1
    EnemyHealth%(Enemy%) = 100
    EnemyCollidable%(Enemy%) = 1
    EnemyCollideForce%(Enemy%) = 1000
    IF EnemyHitboxID%(Enemy%) = 1 THEN
      EnemySprites$(Enemy%) = "durno_ship2"
      EnemyVelocity%(Enemy%,X) = RND(3) - 2
      EnemyVelocity%(Enemy%,Y) = RND(10) + 6
      EnemyHealth%(Enemy%) = 30
      EnemyCollideForce%(Enemy%) = 30
    ENDIF
ENDPROC

DEF PROCspecks_draw
  REM Specks / stars
  FOR Speck%=0 TO 49
    GCOL 0,0
    LINE SpeckLocations%(Speck%,X),SpeckLocations%(Speck%,Y),SpeckLocations%(Speck%,X),(PlayerVelocity% / 3) + SpeckLocations%(Speck%,Y)
    SpeckLocations%(Speck%,Y) = SpeckLocations%(Speck%,Y) - ((Cents% - LastCents%) * PlayerVelocity%/10)
    IF SpeckLocations%(Speck%,Y) < 0 THEN
      SpeckLocations%(Speck%,Y) = SCREENGFXHEIGHT%
      SpeckLocations%(Speck%,X) = RND(SCREENGFXWIDTH%)
    ENDIF
  NEXT Speck%
ENDPROC

REM Move enemy ship (display and physical)
DEF PROCenemy_ship_move
  FOR Enemy%=0 TO MaxEnemies% - 1
    EnemyLocations%(Enemy%,Y) = EnemyLocations%(Enemy%,Y) - ((Cents% - LastCents%) * PlayerVelocity%/20) - ((Cents% - LastCents%) * EnemyVelocity%(Enemy%,Y))

    EnemyLocations%(Enemy%,X) = EnemyLocations%(Enemy%,X) - ((Cents% - LastCents%) * EnemyVelocity%(Enemy%,X))

    IF EnemyLocations%(Enemy%,Y) <= 0 THEN
      PROCrespawn_enemy(Enemy%)
    ENDIF
  NEXT Enemy%
ENDPROC

REM Hud drawing (sprites and real-time)
DEF PROChud_draw
  REM Draw LCARS in top left
  PROCdraw_sprite("lcars",4,SCREENGFXHEIGHT%-180)

  REM Attribute names
  GCOL 0,0
  MOVE 75,SCREENGFXHEIGHT%-50
  PRINT "Sheilds"
  MOVE 75,SCREENGFXHEIGHT%-80
  PRINT "Integrity"
  MOVE 75,SCREENGFXHEIGHT%-110
  PRINT "Velocity"

  REM Attribute values
  GCOL 0,7
  MOVE 130,SCREENGFXHEIGHT%-50
  PRINT PlayerShields%
  MOVE 130,SCREENGFXHEIGHT%-80
  PRINT PlayerStructuralIntegrity%
  MOVE 130,SCREENGFXHEIGHT%-110
  PRINT PlayerVelocity%
ENDPROC

DEF PROCenemy_ship_collide_npc
  FOR Enemy%=0 TO MaxEnemies% - 1
   CollidesWith% = Enemy%

    REM This is our hitbox
    x1 = EnemyLocations%(Enemy%,X) + EnemyHitbox%(EnemyHitboxID%(Enemy%),0)
    y1 = EnemyLocations%(Enemy%,Y) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1)
    w1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),2)
    h1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),3)

    FOR OtherEnemy%=0 TO MaxEnemies% - 1
      REM Collision with an enemy
      IF Enemy% > OtherEnemy% THEN
        x2 = EnemyLocations%(OtherEnemy%,X) + EnemyHitbox%(EnemyHitboxID%(OtherEnemy%),0)
        y2 = EnemyLocations%(OtherEnemy%,Y) + EnemyHitbox%(EnemyHitboxID%(OtherEnemy%),1)
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

REM Handle enemy collisions with player
DEF PROCenemy_ship_collide_player
  FOR Enemy%=0 TO MaxEnemies% - 1

    REM This is our hitbox
    x1 = EnemyLocations%(Enemy%,X) + EnemyHitbox%(EnemyHitboxID%(Enemy%),0)
    y1 = EnemyLocations%(Enemy%,Y) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1)
    w1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),2)
    h1 = EnemyHitbox%(EnemyHitboxID%(Enemy%),3)

    REM Collision with a player
    x2 = PlayerLocation%(X) + PlayerHitbox%(0)
    y2 = PlayerLocation%(Y) + PlayerHitbox%(1)
    w2 = PlayerHitbox%(2)
    h2 = PlayerHitbox%(3)
    IF FNcollide(x1, y1, w1, h1, x2, y2, w2, h2) = 1 THEN
      MOVE x1+w1,y1+h1
      IF EnemyCollidable%(Enemy%) = 1 THEN
        PlayerVelocity% = PlayerVelocity% / 2
        EnemyHealth%(Enemy%) = EnemyHealth%(Enemy%) - 30
        PlayerStructuralIntegrity% = PlayerStructuralIntegrity% - EnemyCollideForce%(Enemy%)
        EnemyCollidable%(Enemy%) = 0
        EnemyVelocity%(Enemy%,X) = 0
        EnemyVelocity%(Enemy%,Y) = 0
      ENDIF
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


REM Calculate player ship's phaser arc
DEF PROCplayer_arc_calculatetarget
  NoseX% = PlayerLocation%(X) + PlayerHitbox%(0) + (PlayerHitbox%(2)/2)
  NoseXLeft% = PlayerLocation%(X) + PlayerHitbox%(0)
  NoseXRight% = PlayerLocation%(X) + PlayerHitbox%(0) + PlayerHitbox%(2)
  NoseY% = (PlayerLocation%(Y) + PlayerHitbox%(1) + PlayerHitbox%(3))

  LeftDistance% = 1000
  LeftID% = -1
  RightDistance% = 1000
  RightID% = -1

  FOR Enemy%=0 TO MaxEnemies% - 1
    LeftCornerX% = EnemyLocations%(Enemy%,X) + EnemyHitbox%(EnemyHitboxID%(Enemy%),X)
    LeftCornerY% = EnemyLocations%(Enemy%,1) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1)
    RightCornerX% = LeftCornerX% + EnemyHitbox%(EnemyHitboxID%(Enemy%),2)
    IF LeftCornerY% > NoseY% THEN
      DistanceY% = LeftCornerY% - NoseY%
      DistanceX% = ABS(NoseX% - ((LeftCornerX% + RightCornerX%) / 2))

      IF (DistanceY%/5) > DistanceX% THEN
        IF (NoseXRight% - ((LeftCornerX% + RightCornerX%) / 2)) > 0 THEN
          IF DistanceY% < LeftDistance% THEN
            LeftDistance% = DistanceY%
            LeftID% = Enemy%
          ENDIF
        ENDIF
        IF (NoseXLeft% - ((LeftCornerX% + RightCornerX%) / 2)) < 0 THEN
          IF DistanceY% < RightDistance% THEN
            RightDistance% = DistanceY%
            RightID% = Enemy%
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  NEXT Enemy%

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

DEF PROCplayer_target_draw
  IF LeftID% >= 0 THEN
    REM LINE PlayerLocation%(X) + PlayerPhaserOffset%(0,X), PlayerLocation%(Y) + PlayerPhaserOffset%(0,Y), EnemyLocations%(LeftID%,X), EnemyLocations%(LeftID%,Y)

    RECT EnemyLocations%(LeftID%,X) + EnemyHitbox%(EnemyHitboxID%(LeftID%),X) - 10, EnemyLocations%(LeftID%,1) + EnemyHitbox%(EnemyHitboxID%(LeftID%),1) - 10, EnemyHitbox%(EnemyHitboxID%(LeftID%),2) + 20, EnemyHitbox%(EnemyHitboxID%(LeftID%),3) + 20

    RECT EnemyLocations%(LeftID%,X) + EnemyHitbox%(EnemyHitboxID%(LeftID%),X) - 8, EnemyLocations%(LeftID%,1) + EnemyHitbox%(EnemyHitboxID%(LeftID%),1) - 8, EnemyHitbox%(EnemyHitboxID%(LeftID%),2) + 16, EnemyHitbox%(EnemyHitboxID%(LeftID%),3) + 16
  ENDIF

  IF RightID% >= 0 THEN
    REM LINE PlayerLocation%(X) + PlayerPhaserOffset%(1,X), PlayerLocation%(Y) + PlayerPhaserOffset%(1,Y), EnemyLocations%(RightID%,X), EnemyLocations%(RightID%,Y)

    RECT EnemyLocations%(RightID%,X) + EnemyHitbox%(EnemyHitboxID%(RightID%),X) -10, EnemyLocations%(RightID%,1) + EnemyHitbox%(EnemyHitboxID%(RightID%),1) -10, EnemyHitbox%(EnemyHitboxID%(RightID%),2) +20, EnemyHitbox%(EnemyHitboxID%(RightID%),3) +20

    RECT EnemyLocations%(RightID%,X) + EnemyHitbox%(EnemyHitboxID%(RightID%),X) -8, EnemyLocations%(RightID%,1) + EnemyHitbox%(EnemyHitboxID%(RightID%),1) -8, EnemyHitbox%(EnemyHitboxID%(RightID%),2) +16, EnemyHitbox%(EnemyHitboxID%(RightID%),3) +16
  ENDIF
ENDPROC

DEF FNpad(String$,Length%)
  OutString$=String$
  WHILE LEN(OutString$) < Length%
    OutString$ = OutString$ + " "
  ENDWHILE
=OutString$

REM Debug prints
DEF PROCdebugoutput
  MOVE 0,500
  PRINT "X:   " + STR$(PlayerLocation%(0)) " Y: " STR$(PlayerLocation%(1))
  PRINT "CPF: " + STR$(Cents% - LastCents%)
  PRINT "Scr: " + STR$(Scr%)
  PRINT "Left: " + STR$(LeftID%)
  PRINT "Right: " + STR$(RightID%)

  FOR Enemy%=0 TO MaxEnemies% - 1
    PRINT "NPC:" STR$(Enemy%) + " " + FNpad(STR$(EnemyLocations%(Enemy%,X)),4) + " " + FNpad(STR$(EnemyLocations%(Enemy%,Y)),4) + " " + FNpad(STR$(EnemyVelocity%(Enemy%,X)),3) + " " + FNpad(STR$(EnemyVelocity%(Enemy%,Y)),3) + " " + FNpad(STR$(EnemyHealth%(Enemy%)),3)
  NEXT Enemy%


  FOR Enemy%=0 TO MaxEnemies% - 1
    RECT EnemyLocations%(Enemy%,X) + EnemyHitbox%(EnemyHitboxID%(Enemy%),X), EnemyLocations%(Enemy%,1) + EnemyHitbox%(EnemyHitboxID%(Enemy%),1), EnemyHitbox%(EnemyHitboxID%(Enemy%),2), EnemyHitbox%(EnemyHitboxID%(Enemy%),3)
  NEXT Enemy%

  RECT PlayerLocation%(X) + PlayerHitbox%(0), PlayerLocation%(Y) + PlayerHitbox%(1), PlayerHitbox%(2), PlayerHitbox%(3)

  IF LeftID% >= 0 THEN
    LINE PlayerLocation%(X) + PlayerPhaserOffset%(0,X), PlayerLocation%(Y) + PlayerPhaserOffset%(0,Y), EnemyLocations%(LeftID%,X), EnemyLocations%(LeftID%,Y)
  ENDIF

  IF RightID% >= 0 THEN
    LINE PlayerLocation%(X) + PlayerPhaserOffset%(1,X), PlayerLocation%(Y) + PlayerPhaserOffset%(1,Y), EnemyLocations%(RightID%,X), EnemyLocations%(RightID%,Y)
  ENDIF
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
