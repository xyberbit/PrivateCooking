# NOX PLAYER

## SETTINGS

%USERPROFILE%\AppData\Local\Nox\*.ini

[setting]  
frames=4  
adb_port=62032  
...

## Recorded Macro Script (unexisting spaces for readability)
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

### ACTION COMMANDS <sub>(subscript for description)</sub>
- **Constants**

	**x-res|y-res** = screen resolution

- **Character Input**

	1 ScRiPtSePaRaToR ***chr*|0** ScRiPtSePaRaToR ***ms***

	***chr*** = typeable character  

- **Key Press/Release**

	0 ScRiPtSePaRaToR x-res|y-res| **KBDPR:*key*:1** ScRiPtSePaRaToR ***ms1***  
	0 ScRiPtSePaRaToR x-res|y-res| **KBDRL:*key*:0** ScRiPtSePaRaToR ***ms2***
  
	***key*** = key code <sub>(key codes)</sub>  

- **Mouse Actions (Click/Drag/Slide)**

	0 ScRiPtSePaRaToR x-res|y-res| **MULTI:1:0:*x1:y1*** ScRiPtSePaRaToR ***ms1*** <sub>(mouse button press)</sub>  
	0 ScRiPtSePaRaToR x-res|y-res| **MULTI:1:2:*x2:y2*** ScRiPtSePaRaToR ***ms2*** <sub>(mouse move, only for drag/slide)</sub>  
	... <sub>(repeat with different x:y for more moves)</sub>  
	0 ScRiPtSePaRaToR x-res|y-res| **MULTI:0:6** ScRiPtSePaRaToR ***msz*** <sub>(ending of multi)</sub>  
	0 ScRiPtSePaRaToR x-res|y-res| **MULTI:0:6** ScRiPtSePaRaToR ***msz***  
	0 ScRiPtSePaRaToR x-res|y-res| **MULTI:0:1** ScRiPtSePaRaToR ***msz***  
	0 ScRiPtSePaRaToR x-res|y-res| **MSBRL:0:0** ScRiPtSePaRaToR ***msz*** <sub>(mouse button release)</sub>  
	
	***x:y*** = coordinate of mouse

- **End of Script**

	5 ScRiPtSePaRaToR ScRiPtSePaRaToR ***ms***  

### KEY CODES
 
|Key |BackSpace|Enter|Shift|Home|Back|Task|
|:--:|:--:     |:--: |:--: |:--:|:--:|:--:|
|Code|14       |28   | 42  |102 |158 |221 |
