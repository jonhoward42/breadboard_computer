.setcpu "65C02"
.debuginfo

; +-------------------------------------------------------------
; | -- Zero Page Segment --
; | Define the start of the zero page segment, reserves space
; | for read and write pointers.
; +-------------------------------------------------------------
.zeropage                       ; Put Read/Write pointers in zero page.
                .org ZP_START0  ; Specify the start of the zero page segment (ZP_START0).
READ_PTR:       .res 1          ; 1 byte for read pointers
WRITE_PTR:      .res 1          ; 1 byte for write pointers

; +-------------------------------------------------------------
; | -- Input Buffer Segment --
; | Defines the input buffer segment, reserves 256 bytes for
; | the input buffer.
; +-------------------------------------------------------------
.segment "INPUT_BUFFER"
INPUT_BUFFER:   .res $100       ; 256 bytes for input buffer

; +-------------------------------------------------------------
; | -- BIOS Segment --
; | This segment contains the BIOS routines for file handling,
; | serial communication and interrupt handling.
; +-------------------------------------------------------------
.segment "BIOS"

; Regiseter Addresses
ACIA_DATA   = $5000 		    ; W65C51S (UART) Data Register Address
ACIA_STATUS = $5001 		    ; W65C51S (UART) Status Register Address
ACIA_CMD    = $5002 		    ; W65C51S (UART) Command Register Address
ACIA_CTRL   = $5003 		    ; W65C51S (UART) Control Register Address
PORTB       = $6000             ; W65C22S (VIA) Port B address
DDRB        = $6002             ; W65C22S (VIA) Data Direction Register address    (Port B)
E           = %01000000         ; W65C22S (VIA/LCD) 'Enable'          pin = pin #2 (Port B)
RW          = %00100000         ; W65C22S (VIA/LCD) 'Read/Write'      pin = pin #3 (Port B)
RS          = %00010000         ; W65C22S (VIA/LCD) 'Register Select' pin = pin #4 (Port B)
T1CL        = $6004             ; W65C22S (VIA/BEEP) Timer 1 (Counter Low)          Control Register address
T1CH        = $6005             ; W65C22S (VIA/BEEP) Timer 1 (Counter High)         Control Register address
ACR         = $600B             ; W65C22S (VIA/BEEP) Timer 1 (Aux Control Register) Control Register address

; BIOS Routines
.include "bios_file_handlers.s"  ; File handlers for LOAD and SAVE operations.
.include "bios_serial.s"         ; Input/output routines for the serial interface.
.include "bios_irq_handler.s"    ; Interrupt request handler for ACIA RX interrupts.
.include "bios_splash.s"         ; LCD splash screen routines.

; LCD Splash Screen Message
LCD_SPLASH1:  .asciiz "-= Jon's 6502 =-"
LCD_SPLASH2:  .asciiz "    SW v1.29"

; Reset Routine - Referenced by the reset vector.
RESET:
                CLD                    ; Clear decimal mode.
                JSR     INIT_BUFFER    ; Initialize the input buffer.
                CLI                    ; Clear interrupt disable flag.
                LDA     #$1F           ; 8-N-1, 19200 baud.
                STA     ACIA_CTRL
                LDY     #$89           ; No parity, no echo, RX interrupts.
                STY     ACIA_CMD

                JSR     LCDINIT        ; Initialize the LCD.
                JSR     PRNT_LCD_SPLASH; Print the splash screen message.
                
                JMP     COLD_START     ; Jump to MS Basic (@ $8000)

LOADWOZMON:
                JSR NOTCR              ; Initialize the WOZMON monitor.

; +-------------------------------------------------------------
; | -- WOZMON --
; | This includes the WOZMON monitor code.
; +-------------------------------------------------------------
.include "wozmon.s"

; +-------------------------------------------------------------
; | -- Reset Vector Segment --
; | This segment defines the reset vector addresses for
; | NMI, RESET, and IRQ.
; +-------------------------------------------------------------
.segment "RESETVEC"
                .word   $0F00          ; NMI vector
                .word   RESET          ; RESET vector
                .word   IRQ_HANDLER    ; IRQ vector