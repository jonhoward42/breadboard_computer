.setcpu "65C02"
.debuginfo
.segment "BIOS"

ACIA_DATA   = $5000 		; W65C51S Data Register Address
ACIA_STATUS = $5001 		; W65C51S Status Register Address
ACIA_CMD    = $5002 		; W65C51S Command Register Address
ACIA_CTRL   = $5003 		; W65C51S Control Register Address

; Input a character from the serial interface.
; On return, the carry flag indicates whether a key was pressed.
; If a key was pressed, the key value will be in the A register.
;
; Modifies: flags, A
CHRIN:
    LDA     ACIA_STATUS     ; Check status.
    AND     #$08            ; Key ready?
    BEQ     @no_keypressed
    LDA     ACIA_DATA       ; Load character.
    JSR     CHROUT          ; Echo character. 
    SEC 
    RTS                     ; Return from subroutine.
@no_keypressed:
    CLC
    RTS                     ; No key pressed, return with C=0.


; Output a character to the serial interface.
; The character to output is in the A register.
; Modifies: flags, A
CHROUT:
                PHA                    ; Save A.
                STA     ACIA_DATA      ; Output character.
                LDA     #$FF           ; Initialize delay loop.
txdelay:        DEC                    ; Decrement A.
                BNE     txdelay        ; Until A gets to 0.
                PLA                    ; Restore A.
                RTS                    ; Return.

.include "wozmon.s"

.segment "RESETVEC"
                .word   $0F00          ; NMI vector
                .word   RESET          ; RESET vector
                .word   $0000          ; IRQ vector