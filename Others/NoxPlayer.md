NOX PLAYER
===

Recorded Macro Script Format (space for readibility, not existing)

## ScRiPtSePaRaToR ACT ScRiPtSePaRaToR ##
│                 │                   │
│                 |                   └── action executed time in ms since the start of script
│                 └────────────────────── action command
└──────────────────────────────────────── action type determines the format of ACT


0 ScRiPtSePaRaToR 480 | 800 | KBDPR:158:0 ScRiPtSePaRaToR 1055

ACTION TYPES

  0 Generic Actions
  1 Character Input

ACTION COMMANDS

  Character Input

  1 ScRiPtSePaRaToR CHR | 0 ScRiPtSePaRaToR #
  1ScRiPtSePaRaToRA|0ScRiPtSePaRaToR#

    1ScRiPtSePaRaToR^|0ScRiPtSePaRaToR6849
  1ScRiPtSePaRaToR&|0ScRiPtSePaRaToR7125
  1ScRiPtSePaRaToR*|0ScRiPtSePaRaToR7438
  1ScRiPtSePaRaToR(|0ScRiPtSePaRaToR7738
  1ScRiPtSePaRaToR)|0ScRiPtSePaRaToR8029

# a number, read descriptions
ScRiPtSePaRaToR as its name "ScriptSeparator"
| is the argument separator
It's an end line when nothings between ScRiPtSePaRaToR's and the first # is total number of commands

ACTIONS:

KBDPR:158:0 - press Back key

KBDRL:158:0 - release Back

KBDPR:102:0 - same for Home

KBDRL:102:0

KBDPR:221:0 - 'recent apps' button

KBDRL:221:0

MULTI:1:0:xx:yy - touch down at xx,yy coordinates

MULTI:0:6 and MSBRL:1337814:-1072938 - two lines for touch up, never experimented if both are really needed, just copied from macro; numbers in MSBRL are always the same, they are not coordinates

MULTI:1:2:xx:yy - used after touch down, this command swipes to xx,yy. Used repeatedly for short intervals, should be followed with touch up command for 'end of swipe'.

%USERPROFILE%\AppData\Local\Nox\*.ini
[setting]
  astc=
  rendering_cache=true|false
  frames
  adb_port

  


