REM Useful constants
X = 0
Y = 1

REM Show/hide debug display
DebugOut%=0

REM Used for centiseconds per frame calcs
Cents% = TIME

PROCaudio_setup

PROCgfx_setup

PROCmain_scene1

END

DEF PROCgfx_setup
  CLS
  SCREENMODE% = 28
  sprite_area% = FNload_sprites("Spr")
  REMIF SCREENMODE% = 32 THEN
  REM  SCREENGFXWIDTH%=1600
  REM  SCREENGFXHEIGHT%=1200
  REM  MaxEnemies% = 10
  REM  PlayerYHeightDivide%=8
  REMENDIF
  IF SCREENMODE% = 28 THEN
    SCREENGFXWIDTH%=1280
    SCREENGFXHEIGHT%=960
    MaxEnemies% = 5
    PlayerYHeightDivide%=20
  ENDIF

  MODE SCREENMODE%

  REM Position text cursor at graphics location
  VDU 5

ENDPROC

DEF PROCaudio_setup
  SOUND ON
  VOICES 4
  VOICE 1,"WaveSynth-Beep"
  VOICE 2,"Percussion-Noise"
  VOICE 3,"Percussion-Soft"
  VOICE 4,"Percussion-Noise"
ENDPROC

DEF PROCmain_scene1
  REM Current graphics buffer
  Scr% = 1

  REM Make sure to reset this here so initial stuff is ok
  Cents% = TIME

  DIM PlayerLocation%(1)
  PlayerLocation%(X) = SCREENGFXWIDTH%/2
  PlayerLocation%(Y) = SCREENGFXHEIGHT%/PlayerYHeightDivide%
  PlayerShields%=100
  PlayerStructuralIntegrity%=100
  PlayerSprite$ = "player_ship"
  PlayerExplodeNextFrame% = 0
  PlayerRemainingDistance% = 1500000
  DIM PlayerHitbox%(3)
  PlayerHitbox%() = 0,0,60,81
  DieEnd% = 0
  DIM PlayerPhaserOffset%(1,1)
  PlayerPhaserOffset%(0,X) = 20
  PlayerPhaserOffset%(0,Y) = 75
  PlayerPhaserOffset%(1,X) = 40
  PlayerPhaserOffset%(1,Y) = 75
  PlayerPhaserDamagePerSecond% = 3

  LeftID% = -1
  RightID% = -1
  LeftFiring% = 0
  RightFiring% = 0

  DIM EnemyHitbox%(1,3)
  EnemyHitbox%(0,0) = 0
  EnemyHitbox%(0,1) = 0
  EnemyHitbox%(0,2) = 48
  EnemyHitbox%(0,3) = 74
  EnemyHitbox%(1,0) = 0
  EnemyHitbox%(1,1) = 0
  EnemyHitbox%(1,2) = 38
  EnemyHitbox%(1,3) = 56

  XMovePerCent%=10
  ResetShipSprite% = 0

  DIM EnemyLocations%(MaxEnemies% - 1,1)
  DIM EnemySprites$(MaxEnemies% - 1)
  DIM EnemyHitboxID%(MaxEnemies% - 1)
  DIM EnemyVelocity%(MaxEnemies% - 1,1)
  DIM EnemyHealth%(MaxEnemies% - 1)
  DIM EnemyCollidable%(MaxEnemies% -1)
  DIM EnemyCollideForce%(MaxEnemies% -1)
  DIM EnemyExplodeNextFrame%(MaxEnemies% -1)
  DIM EnemyNextFire%(MaxEnemies% -1)
  DIM EnemyFireInterval%(MaxEnemies% -1)

  MaxProjectiles% = 10
  DIM ProjectileLocations%(MaxProjectiles% - 1,1)
  DIM ProjectileVelocity%(MaxProjectiles% - 1,1)
  DIM ProjectileState%(MaxProjectiles% - 1)
  DIM ProjectileFrame%(MaxProjectiles% - 1)
  DIM ProjectileMaxFrame%(MaxProjectiles% - 1)
  DIM ProjectileDamage%(MaxProjectiles% - 1)
  DIM ProjectileSprite$(MaxProjectiles% - 1)
  DIM ProjectileFrameInterval%(MaxProjectiles% - 1)
  DIM ProjectileFrameNext%(MaxProjectiles% - 1)

  REM Random it up for now
  FOR Enemy%=0 TO MaxEnemies% - 1
    PROCrespawn_enemy(Enemy%)
  NEXT Enemy%

  FOR Projectile%=0 TO MaxProjectiles% - 1
    ProjectileState%(MaxProjectiles% - 1) = 0
  NEXT Projectile%




  DIM SpeckLocations%(49,1)
  FOR Speck%=0 TO 49
    SpeckLocations%(Speck%,X) = RND(SCREENGFXWIDTH%)
    SpeckLocations%(Speck%,Y) = RND(SCREENGFXHEIGHT%)
  NEXT Speck%

  REPEAT
    REM Store current time and last time
    LastCents% = Cents%
    Cents% = TIME

    REM Mission distance left
    PlayerRemainingDistance% = PlayerRemainingDistance% - (Cents% - LastCents%) * 100

    REM Damage is always handled
    PROCplayer_ship_handle_damage
    PROCenemy_ship_handle_damage

    REM Enemy/projectile movement - even if player dead
    PROCenemy_ship_move
    PROCprojectile_move

    IF PlayerStructuralIntegrity% > 0 THEN
      REM Controls
      PROCinputs

      REM NPCs
      PROCenemy_ship_collide_player
      PROCprojectile_collide_player
      REM PROCenemy_ship_collide_npc

      REM Player Weapons calculations
      PROCplayer_arc_calculatetarget
      PROCplayer_weapons_damage

      REM Environment calculations
      PROCspecks_move
    ENDIF


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

    REM Draw enemy stuff
    PROCenemy_ship_draw
    PROCprojectile_draw

    IF PlayerStructuralIntegrity% > 0 THEN
     PROCplayer_weapons_draw
    ENDIF

    REM UI
    PROChud_draw

    IF DebugOut% = 1 THEN
      PROCdebugoutput
    ENDIF

  UNTIL FALSE

ENDPROC

DEF PROCprojectile_move
  FOR Projectile%=0 TO MaxProjectiles% - 1
    IF ProjectileState%(Projectile%) > 0 THEN

      REM Calculate new locations from velocity
      ProjectileLocations%(Projectile%,0) +=  ((Cents% - LastCents%) * ProjectileVelocity%(Projectile%,0))
      ProjectileLocations%(Projectile%,1) -=  ((Cents% - LastCents%) * ProjectileVelocity%(Projectile%,1))

      REM If they go out of bounds then disable
      IF ProjectileLocations%(Projectile%,0) > SCREENGFXWIDTH% THEN
        ProjectileState%(Projectile%) = 0
      ENDIF
      IF ProjectileLocations%(Projectile%,0) < 0 THEN
        ProjectileState%(Projectile%) = 0
      ENDIF
      IF ProjectileLocations%(Projectile%,1) > (SCREENGFXHEIGHT% * 2) THEN
        ProjectileState%(Projectile%) = 0
      ENDIF
      IF ProjectileLocations%(Projectile%,1) < 0 THEN
        ProjectileState%(Projectile%) = 0
      ENDIF

    ENDIF
  NEXT Projectile%
ENDPROC

DEF PROCprojectile_draw
  FOR Projectile%=0 TO MaxProjectiles% - 1
    IF ProjectileState%(Projectile%) > 0 THEN
      IF Cents% > ProjectileFrameNext%(Projectile%) THEN
        ProjectileFrame%(Projectile%) = ProjectileFrame%(Projectile%) + 1
        ProjectileFrameNext%(Projectile%) = Cents% + ProjectileFrameInterval%(Projectile%)
      ENDIF
      IF ProjectileFrame%(Projectile%) > ProjectileMaxFrame%(Projectile%) THEN
        ProjectileFrame%(Projectile%) = 1
      ENDIF
      PROCdraw_sprite(ProjectileSprite$(Projectile%) + STR$(ProjectileFrame%(Projectile%)),ProjectileLocations%(Projectile%,0),ProjectileLocations%(Projectile%,1))
    ENDIF
  NEXT Projectile%
ENDPROC

DEF PROCspawn_projectile(Projectile%,Px%,Py%,Vx%,Vy%,Sprite$,Damage%)
  IF Projectile% < 0 THEN
    FOR P%=0 TO MaxProjectiles% - 1
        IF ProjectileState%(P%) = 0 THEN
          Projectile% = P%
        ENDIF
    NEXT P%
  ENDIF

  REM If no velocity X specified we're targetting the player
  REM TODO: This is baaaaadly broken. Suspect something floating point..
  IF Vx% = 0 THEN
    Velocity% = 10
    Xdistance% = PlayerLocation%(X) - Px%
    Ydistance% = Py% - PlayerLocation%(Y)
    distance% = SQR((Xdistance%^2) + (Ydistance%^2))
    Vx% = Xdistance% / (distance% / Velocity%)
    Vy% = Ydistance% / (distance% / Velocity%)
  ENDIF

  REM If no free IDs then we go without
  IF Projectile% >= 0 THEN
    ProjectileLocations%(Projectile%,X) = Px%
    ProjectileLocations%(Projectile%,Y) = Py%
    ProjectileVelocity%(Projectile%,X) = Vx%
    ProjectileVelocity%(Projectile%,Y) = Vy%
    ProjectileState%(Projectile%) = 1
    ProjectileFrame%(Projectile%) = 1
    ProjectileMaxFrame%(Projectile%) = 2
    ProjectileSprite$(Projectile%) = Sprite$
    ProjectileDamage%(Projectile%) = Damage%
    ProjectileFrameInterval%(Projectile%) = 10
    ProjectileFrameNext%(Projectile%) = Cents% + ProjectileFrameInterval%(Projectile%)
  ENDIF

ENDPROC

DEF PROCplayer_weapons_damage
  IF LeftID% < 0 THEN
    LeftFiring% = 0
  ENDIF
  IF RightID% < 0 THEN
    RightFiring% = 0
  ENDIF

  IF LeftFiring% = 1 THEN
    EnemyHealth%(LeftID%) = EnemyHealth%(LeftID%) - ((Cents% - LastCents%) * PlayerPhaserDamagePerSecond%)
  ENDIF

  IF RightFiring% = 1 THEN
    EnemyHealth%(RightID%) = EnemyHealth%(RightID%) - ((Cents% - LastCents%) * PlayerPhaserDamagePerSecond%)
  ENDIF
ENDPROC


DEF PROCplayer_weapons_draw
  REM If no targets then dont fire phasers
  IF LeftID% < 0 THEN
    LeftFiring% = 0
  ENDIF
  IF RightID% < 0 THEN
    RightFiring% = 0
  ENDIF

  REM Phasers are orange
  GCOL 0,7

  IF LeftFiring% = 1 THEN
    LINE PlayerLocation%(X) + PlayerPhaserOffset%(0,X), PlayerLocation%(Y) + PlayerPhaserOffset%(0,Y), EnemyLocations%(LeftID%,X) + (EnemyHitbox%(EnemyHitboxID%(LeftID%),2)/2), EnemyLocations%(LeftID%,Y)
  ENDIF

  IF RightFiring% = 1 THEN
    LINE PlayerLocation%(X) + PlayerPhaserOffset%(1,X), PlayerLocation%(Y) + PlayerPhaserOffset%(1,Y), EnemyLocations%(RightID%,X) + (EnemyHitbox%(EnemyHitboxID%(RightID%),2)/2), EnemyLocations%(RightID%,Y)
  ENDIF
ENDPROC

DEF PROCplayer_ship_handle_damage
  IF PlayerStructuralIntegrity% <= 0 THEN
      IF TIME > PlayerExplodeNextFrame% THEN
        PlayerExplodeNextFrame% = TIME + 4
        IF PlayerSprite$ = "player_ship" THEN
          DieEnd% = TIME + 150
         SOUND 2,-5, 20,50
        ENDIF
        CASE PlayerSprite$ OF
           WHEN "player_ship": PlayerSprite$ = "explode_shp1"
           WHEN "explode_shp1": PlayerSprite$ = "explode_shp2"
           WHEN "explode_shp2": PlayerSprite$ = "explode_shp3"
           WHEN "explode_shp3": PlayerSprite$ = "explode_shp4"
           WHEN "explode_shp4": PlayerSprite$ = "explode_shp1"
        ENDCASE
      ENDIF
      IF TIME > DieEnd% THEN
        PlayerSprite$ = "default"
        CLS
        PRINT "YOU DED"
        END
      ENDIF
  ENDIF
ENDPROC

DEF PROCenemy_ship_handle_damage
  FOR Enemy%=0 TO MaxEnemies% - 1
    REM Destruction
    IF EnemyHealth%(Enemy%) <= 0 THEN
       EnemyNextFire%(Enemy%) = 0
      EnemyCollidable%(Enemy%) = 0
      IF EnemySprites$(Enemy%) = "durno_ship2" THEN
        SOUND 1,-5,0,100
        SOUND 3,-15,0,1000
        SOUND 2,-10,1,100
      ENDIF
      IF TIME > EnemyExplodeNextFrame%(Enemy%) THEN
        EnemyExplodeNextFrame%(Enemy%) = TIME + 4
        CASE EnemySprites$(Enemy%) OF
           WHEN "durno_ship": EnemySprites$(Enemy%) = "explode_shp1"
           WHEN "durno_ship2": EnemySprites$(Enemy%) = "explode_shp1"
           WHEN "explode_shp1": EnemySprites$(Enemy%) = "explode_shp2"
           WHEN "explode_shp2": EnemySprites$(Enemy%) = "explode_shp3"
           WHEN "explode_shp3": EnemySprites$(Enemy%) = "explode_shp4"
           WHEN "explode_shp4": EnemySprites$(Enemy%) = "explode_shp1"
        ENDCASE
      ENDIF
    ENDIF

  NEXT Enemy%
ENDPROC

DEF PROCrespawn_enemy(Enemy%)
    EnemyLocations%(Enemy%,X) = RND(SCREENGFXWIDTH%)
    EnemyLocations%(Enemy%,Y) = SCREENGFXHEIGHT% + (RND(SCREENGFXHEIGHT%/2) * (Enemy% + 1))
    EnemySprites$(Enemy%) = "durno_ship"
    EnemyVelocity%(Enemy%,X) = 0
    EnemyVelocity%(Enemy%,Y) = RND(3) + 2
    EnemyHitboxID%(Enemy%) = RND(2)-1
    EnemyHealth%(Enemy%) = 1000
    EnemyCollidable%(Enemy%) = 1
    EnemyCollideForce%(Enemy%) = 1000
    EnemyExplodeNextFrame%(Enemy%) = 0
    EnemyNextFire%(Enemy%) = Cents%
    EnemyFireInterval%(Enemy%) = 200

    IF EnemyHitboxID%(Enemy%) = 1 THEN
      EnemySprites$(Enemy%) = "durno_ship2"
      EnemyVelocity%(Enemy%,X) = RND(3) - 2
      EnemyVelocity%(Enemy%,Y) = RND(2) + 6
      EnemyHealth%(Enemy%) = 30
      EnemyCollideForce%(Enemy%) = 30
      EnemyNextFire%(Enemy%) = 0
    ENDIF
ENDPROC

DEF PROCspecks_draw
  REM Specks / stars
  FOR Speck%=0 TO 49
    GCOL 0,0
    LINE SpeckLocations%(Speck%,X),SpeckLocations%(Speck%,Y),SpeckLocations%(Speck%,X),30 + SpeckLocations%(Speck%,Y)
  NEXT Speck%
ENDPROC

DEF PROCspecks_move
  REM Specks / stars
  FOR Speck%=0 TO 49
    SpeckLocations%(Speck%,Y) = SpeckLocations%(Speck%,Y) - ((Cents% - LastCents%) * 2)
    IF SpeckLocations%(Speck%,Y) < 0 THEN
      SpeckLocations%(Speck%,Y) = SCREENGFXHEIGHT%
      SpeckLocations%(Speck%,X) = RND(SCREENGFXWIDTH%)
    ENDIF
  NEXT Speck%
ENDPROC

REM Move enemy ship (display and physical)
DEF PROCenemy_ship_move
  FOR Enemy%=0 TO MaxEnemies% - 1
    EnemyLocations%(Enemy%,Y) = EnemyLocations%(Enemy%,Y) - ((Cents% - LastCents%) * EnemyVelocity%(Enemy%,Y))

    EnemyLocations%(Enemy%,X) = EnemyLocations%(Enemy%,X) - ((Cents% - LastCents%) * EnemyVelocity%(Enemy%,X))

    IF EnemyLocations%(Enemy%,Y) < SCREENGFXHEIGHT%/2 THEN
      EnemyNextFire%(Enemy%) = 0
    ENDIF

    IF EnemyNextFire%(Enemy%) > 0 THEN
      IF EnemyNextFire%(Enemy%) < Cents% THEN
        PROCspawn_projectile(-1,EnemyLocations%(Enemy%,X),EnemyLocations%(Enemy%,Y),0,EnemyVelocity%(Enemy%,Y),"photon",10)
        EnemyNextFire%(Enemy%) = Cents% + EnemyFireInterval%(Enemy%)
      ENDIF
    ENDIF

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
  MOVE 75,SCREENGFXHEIGHT%-140
  PRINT "Distance"

  REM Attribute values
  GCOL 0,7
  MOVE 130,SCREENGFXHEIGHT%-50
  PRINT PlayerShields%
  MOVE 130,SCREENGFXHEIGHT%-80
  PRINT PlayerStructuralIntegrity%

  MOVE 130,SCREENGFXHEIGHT%-140
  PRINT PlayerRemainingDistance% DIV 1000
ENDPROC

REM Not using this, NPC/NPC collide is needless maths..
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
        EnemyHealth%(Enemy%) = EnemyHealth%(Enemy%) - 300
        PlayerStructuralIntegrity% = PlayerStructuralIntegrity% - EnemyCollideForce%(Enemy%)
        EnemyCollidable%(Enemy%) = 0
        EnemyVelocity%(Enemy%,Y) = EnemyVelocity%(Enemy%,Y) / 2
        EnemyVelocity%(Enemy%,X) = EnemyVelocity%(Enemy%,X) * 4
      ENDIF
    ENDIF
  NEXT Enemy%
ENDPROC

REM Handle projectile collisions with player
DEF PROCprojectile_collide_player
  FOR P%=0 TO MaxProjectiles% - 1

    REM This is our hitbox
    x1 = ProjectileLocations%(P%,X)
    y1 = ProjectileLocations%(P%,Y)
    w1 = 10
    h1 = 10

    REM Collision with a player
    x2 = PlayerLocation%(X) + PlayerHitbox%(0)
    y2 = PlayerLocation%(Y) + PlayerHitbox%(1)
    w2 = PlayerHitbox%(2)
    h2 = PlayerHitbox%(3)
    IF FNcollide(x1, y1, w1, h1, x2, y2, w2, h2) = 1 THEN
      MOVE x1+w1,y1+h1
      PlayerStructuralIntegrity% = PlayerStructuralIntegrity% - ProjectileDamage%(P%)
      ProjectileState%(P%) = 0
      ProjectileLocations%(P%,0) = 0
    ENDIF
  NEXT P%
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
    ShipSprite$ = PlayerSprite$
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
    IF PlayerLocation%(0) > (SCREENGFXWIDTH% - PlayerHitbox%(2)) THEN
       PlayerLocation%(0) = (SCREENGFXWIDTH% - PlayerHitbox%(2))
       ShipSprite$ = "player_ship"
    ENDIF
  ENDIF
  IF INKEY(-26) THEN
    ShipSprite$ = "player_shipl"
    ResetShipSprite% = Cents% + 20
    PlayerLocation%(0) = PlayerLocation%(0) - (XMovePerCent% * (Cents% - LastCents%))
    IF PlayerLocation%(0) < 0 THEN
       PlayerLocation%(0) = 0
       ShipSprite$ = "player_ship"
    ENDIF
  ENDIF
  IF INKEY(-99) THEN
     LeftFiring% = 1
     RightFiring% = 1
  ENDIF
  IF INKEY(-34) THEN
    PROCspawn_projectile(-1,SCREENGFXWIDTH%/2,SCREENGFXHEIGHT%/2,0,2,"photon",50)
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
    MOVE EnemyLocations%(LeftID%,X), EnemyLocations%(LeftID%,Y) - 20
    PRINT STR$(EnemyHealth%(LeftID%))
  ENDIF

  IF RightID% >= 0 THEN
    REM LINE PlayerLocation%(X) + PlayerPhaserOffset%(1,X), PlayerLocation%(Y) + PlayerPhaserOffset%(1,Y), EnemyLocations%(RightID%,X), EnemyLocations%(RightID%,Y)

    RECT EnemyLocations%(RightID%,X) + EnemyHitbox%(EnemyHitboxID%(RightID%),X) -10, EnemyLocations%(RightID%,1) + EnemyHitbox%(EnemyHitboxID%(RightID%),1) -10, EnemyHitbox%(EnemyHitboxID%(RightID%),2) +20, EnemyHitbox%(EnemyHitboxID%(RightID%),3) +20

    RECT EnemyLocations%(RightID%,X) + EnemyHitbox%(EnemyHitboxID%(RightID%),X) -8, EnemyLocations%(RightID%,1) + EnemyHitbox%(EnemyHitboxID%(RightID%),1) -8, EnemyHitbox%(EnemyHitboxID%(RightID%),2) +16, EnemyHitbox%(EnemyHitboxID%(RightID%),3) +16
    MOVE EnemyLocations%(RightID%,X), EnemyLocations%(RightID%,Y) - 20
    PRINT STR$(EnemyHealth%(RightID%))
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
  PRINT "Left: " + STR$(LeftID%) + " - " + STR$(LeftFiring%)
  PRINT "Right: " + STR$(RightID%) + " - " + STR$(RightFiring%)

  FOR Enemy%=0 TO MaxEnemies% - 1
    PRINT "NPC:" STR$(Enemy%) + ": " + FNpad(STR$(EnemyLocations%(Enemy%,X)),4) + "," + FNpad(STR$(EnemyLocations%(Enemy%,Y)),4) + " V: " + FNpad(STR$(EnemyVelocity%(Enemy%,X)),2) + "," + FNpad(STR$(EnemyVelocity%(Enemy%,Y)),2)
    PRINT "H: " + FNpad(STR$(EnemyHealth%(Enemy%)),3)
  NEXT Enemy%

  FOR P%=0 TO MaxProjectiles% - 1
    PRINT "P:" STR$(P%) + ": " + FNpad(STR$(ProjectileLocations%(P%,X)),4) + "," + FNpad(STR$(ProjectileLocations%(P%,Y)),4) + " V: " + FNpad(STR$(ProjectileVelocity%(P%,X)),2) + "," + FNpad(STR$(ProjectileVelocity%(P%,Y)),2) + STR$(ProjectileState%(P%))
  NEXT P%

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
