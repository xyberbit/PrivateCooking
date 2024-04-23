# NOX PLAYER

## SETTINGS

%USERPROFILE%\AppData\Local\Nox\*.ini

[setting]  
frames=4
adb_port=62032

## Recorded Macro Script (unexisting space for readibility)
```
# ScRiPtSePaRaToR ACT ScRiPtSePaRaToR #
│                 │                   │
│                 |                   └── action executed time in milliseconds from the start of script
│                 └────────────────────── action command
└──────────────────────────────────────── action type determines the format of ACT
```

### ACTION TYPES

- 0 = Coordinated Actions
- 1 = Character Input
- 5 = End of Script

### ACTION COMMANDS

- **Character Input**

	**1** ScRiPtSePaRaToR **CHR | 0** ScRiPtSePaRaToR **ms**

	CHR = typeable character
	0 = end of action

- **Key Press/Release**

	**0** ScRiPtSePaRaToR **X-Res | Y-Res | KBDPR : KEY : 1** ScRiPtSePaRaToR **ms**
	**0** ScRiPtSePaRaToR **X-Res | Y-Res | KBDRL : KEY : 0** ScRiPtSePaRaToR **ms**

	X-Res | Y-Res = screen resolution
	KEY = key code
	1 = coming actions
	0 = end of action

- **Mouse Button Press/Release**

- **Multiple Actions**

	**0** ScRiPtSePaRaToR **MULTI X-Res | Y-Res | KBDPR : KEY : 1** ScRiPtSePaRaToR **ms**

- **End of Script**

	**5** ScRiPtSePaRaToR ScRiPtSePaRaToR **ms**
 
KEY CODE

158 Android Back
102 Android Home
221 Android Task


MULTI:1:0:xx:yy - touch down at xx,yy coordinates

MULTI:0:6 and MSBRL:1337814:-1072938 - two lines for touch up, never experimented if both are really needed, just copied from macro; numbers in MSBRL are always the same, they are not coordinates

MULTI:1:2:xx:yy - used after touch down, this command swipes to xx,yy. Used repeatedly for short intervals, should be followed with touch up command for 'end of swipe'.
