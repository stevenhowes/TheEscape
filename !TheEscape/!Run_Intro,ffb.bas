MODE 28
OFF
CLS

sprite_area% = FNload_sprites("Spr")
PROCdraw_sprite("intro_28",320,400)


DIM Notes$(12)
Notes$() = "A","A#","B","C","C#","D","D#","E","F","F#","G","G#"

MaxComp% = 999
DIM CompositionStart%(MaxComp%)
DIM CompositionNote%(MaxComp%)
DIM CompositionVolume%(MaxComp%)
DIM CompositionChannel%(MaxComp%)
DIM CompositionLength%(MaxComp%)

PRINT "Loading composition"

CurrentNote% = 0
CurrentStart% = 0

REM DUn, dun, daan duhhn
PROCAddNote(CurrentStart%,1,"A4#",200)
PROCAddNote(CurrentStart%,2,"A5#",200)
CurrentStart% += 200
PROCAddNote(CurrentStart%,1,"F3",200)
PROCAddNote(CurrentStart%,2,"F4",200)
CurrentStart% += 200
PROCAddNote(CurrentStart%,1,"G3#",200)
PROCAddNote(CurrentStart%,2,"G4#",200)
CurrentStart% += 200
PROCAddNote(CurrentStart%,1,"C3",200)
PROCAddNote(CurrentStart%,2,"C4",200)
CurrentStart% += 200

REM DUn, dun, daan duhhn
PROCAddNote(CurrentStart%,1,"A3#",200)
PROCAddNote(CurrentStart%,2,"A4#",200)
CurrentStart% += 200
PROCAddNote(CurrentStart%,1,"F2",200)
CurrentStart% += 200
PROCAddNote(CurrentStart%,2,"G2#",200)
CurrentStart% += 200
PROCAddNote(CurrentStart%,1,"C2",200)
CurrentStart% += 250

REM Duh
PROCAddNote(CurrentStart%,3,"A3#",300)
PROCAddNote(CurrentStart%,4,"A2#",300)
CurrentStart% += 200

REM Dun De Da
PROCAddNote(CurrentStart%,1,"F1",20)
CurrentStart% += 50
PROCAddNote(CurrentStart%,2,"A2#",5)
CurrentStart% += 20
PROCAddNote(CurrentStart%,1,"D2#",200)
CurrentStart% += 180


PROCAddNote(CurrentStart%,2,"D2",50)
CurrentStart% += 50
PROCAddNote(CurrentStart%,1,"A2#",30)
CurrentStart% += 30
PROCAddNote(CurrentStart%,2,"G1",50)
CurrentStart% += 50
PROCAddNote(CurrentStart%,1,"C2",50)
CurrentStart% += 50
PROCAddNote(CurrentStart%,3,"A2#",100)
PROCAddNote(CurrentStart%,4,"F2",100)
CurrentStart% += 100

PRINT "Loaded"


SOUND ON
VOICES 4
VOICE 1,"WaveSynth-Beep"
VOICE 2,"WaveSynth-Beep"
VOICE 3,"WaveSynth-Beep"
VOICE 4,"WaveSynth-Beep"

StartCents% = TIME

FOR NoteID%=0 TO CurrentNote%
  IF CompositionChannel%(NoteID%) > 0 THEN
    WHILE CompositionStart%(NoteID%) > (TIME - StartCents%)
    ENDWHILE
    PRINT STR$(CompositionChannel%(NoteID%)) + " " + STR$(CompositionVolume%(NoteID%)) + " " + STR$(CompositionNote%(NoteID%)) + " " + STR$(CompositionLength%(NoteID%))
    SOUND CompositionChannel%(NoteID%),CompositionVolume%(NoteID%),CompositionNote%(NoteID%),CompositionLength%(NoteID%)
    Key% = INKEY(0)
    IF Key% >= 0 END
  ENDIF
NEXT NoteID%


PROCDelay(300)
END

DEF PROCAddNote(Start%,Channel%,RealNote$,Length%)
  CompositionStart%(CurrentNote%) = Start%
  CompositionNote%(CurrentNote%) = FNEncodeNote(RealNote$)
  CompositionVolume%(CurrentNote%) = -10
  CompositionChannel%(CurrentNote%) = Channel%
  CompositionLength%(CurrentNote%) = Length%
  CurrentNote% += 1
ENDPROC

DEF FNEncodeNote(Note$)
  Octave% = VAL(MID$(Note$,2,1))
  IF LEN(Note$) = 3 THEN
    Note$ = LEFT$(Note$,1) + RIGHT$(Note$,1)
  ELSE
    Note$ = LEFT$(Note$,1)
  ENDIF


  NoteByte% = -1
  FOR NoteCount% = 0 TO 12
    IF Notes$(NoteCount%) = Note$ THEN
      NoteByte% = NoteCount%
    ENDIF
  NEXT NoteCount%
  NoteByte% = 41 + (4 * NoteByte%) + ((Octave% - 2) * 48)
  IF NoteByte% < 0 THEN
    NoteByte% = 0
  ENDIF
=NoteByte%

REM Delay routine - thanks Sophie
DEF PROCDelay(n)
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
