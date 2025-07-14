# Homebrew code for my Breadboard computer

## Version 1.29 - Initial Homebrew release
The code held here essentially mirrors that of Ben Eater's series (up to Video 29) but with a few modifications of my own:

1. BIOS reworked quite a lot to include code & definitions from other areas:
    - Register addresses now maintained in the BIOS code
    - Reset code (referenced by the reset vector) now held in the BIOS code - not within WOZMON
    - LCD_INIT now held in the BIOS reset code - not with MS Basic (init.s)
    - Dummy file handers moved to a separate file (bios_file_handlers.s) and included in the BIOS code
    - IRQ handler moved to a separate file (bios_irq_handler.s) and included in the BIOS code
    - Serial / UART code moved to a separate file (bios_serial.s) and included in the BIOS code
    - BIOS / Software version displayed to the LCD screen on reset 

2. The new reset code (now in the BIOS) jumps to "COLD_START", immediately loading MS BASIC

3. Additional commands added to MS Basic:
    - LCDCR     - CR to the LCD (jump to line 2)
    - LCDCLS    - Clears the LCD screen
    - WOZMON    - Jumpts to LOADWOZMON (now in the BIOS) and loads WOZMON from BASIC

# Some BEEP programs in BASIC
Basic scale:
```
10 BEEP 956, 60
20 BEEP 852, 60
30 BEEP 759, 60
40 BEEP 716, 60
50 BEEP 638, 60
60 BEEP 568, 60
70 BEEP 506, 60
80 BEEP 478, 60
90 BEEP 506, 60
100 BEEP 568, 60
110 BEEP 638, 60
120 BEEP 716, 60
130 BEEP 759, 60
140 BEEP 852, 60
150 BEEP 956, 60
```

Super Mario:
```
10 DIM N(78)
20 DIM D(78)
30 FOR I = 1 TO 78
40 READ N(I)
50 NEXT I
60 FOR I = 1 TO 78
70 READ D(I)
80 NEXT I
90 FOR I = 1 TO 78
100 BEEP N(I), D(I)
110 NEXT I
120 REM -- Notes --
140 DATA 190,190,0,190,0,239,190,0,159,0,0,0,319,0,0,0,239,0,0,319,0,0
150 DATA 379,0,0,284,0,253,0,268,284,0,319,190,159,142,0,179,159,0,190
160 DATA 0,239,213,253,0,0,239,0,0,319,0,0,379,0,0,284,0,253,0,268,284
170 DATA 0,319,190,159,142,0,179,159,0,190,0,239,213,253,0,0
180 REM -- Durations --
190 DATA 75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75
200 DATA 75,75,75,75,75,75,75,75,75,75,75,75,75,75,100,100,100,75,75,75,75
210 DATA 75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75,75
220 DATA 75,75,75,75,100,100,100,75,75,75,75,75,75,75,75,75,75,75,75,75
```