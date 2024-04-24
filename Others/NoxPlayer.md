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

### ACTION COMMANDS ~(subscript for description)~

- **Character Input**

	**1** ScRiPtSePaRaToR ***chr* |0** ScRiPtSePaRaToR **ms**

	*chr* = typeable character  

- **Key Press/Release**

	**0** ScRiPtSePaRaToR **x-res|y-res | KBDPR: *key* :1** ScRiPtSePaRaToR **ms1**  
	**0** ScRiPtSePaRaToR **x-res|y-res | KBDRL: *key* :0** ScRiPtSePaRaToR **ms2**

	x-res|y-res = screen resolution  
	*key* = key code ~(key code table)~  

- **Mouse Actions (Click/Drag/Slide)**

	**0** ScRiPtSePaRaToR **x-res|y-res | MULTI:1:0: *x1:y1*** ScRiPtSePaRaToR **ms1** ~(mouse button press)~ 
	**0** ScRiPtSePaRaToR **x-res|y-res | MULTI:1:2: *x2:y2*** ScRiPtSePaRaToR **ms2** ~(mouse move, only for drag/slide)~  
		... ~(repeat with different x:y for more moves)~  
	**0** ScRiPtSePaRaToR **x-res|y-res | MULTI:0:6** ScRiPtSePaRaToR **msz** ~(mouse button release, 4 continueous actions)~ 
	**0** ScRiPtSePaRaToR **x-res|y-res | MULTI:0:6** ScRiPtSePaRaToR **msz**
	**0** ScRiPtSePaRaToR **x-res|y-res | MULTI:0:1** ScRiPtSePaRaToR **msz**
	**0** ScRiPtSePaRaToR **x-res|y-res | MSBRL:0:0** ScRiPtSePaRaToR **msz**
	
	x-res|y-res = screen resolution  
	*x:y* = coordinate of mouse
	MSBRL = Mouse Button Release

- **End of Script**

	**5** ScRiPtSePaRaToR ScRiPtSePaRaToR **ms**  

### KEY CODE TABLE
 
|Key |BackSpace|Enter|Shift|Home|Back|Task|
|:--:|:--:     |:--: |:--: |:--:|:--:|:--:|
|Code|14       |28   | 42  |102 |158 |221 |
