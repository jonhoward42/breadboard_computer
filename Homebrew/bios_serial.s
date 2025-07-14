.segment "BIOS"

; Input a character from the serial interface.
; On return, the carry flag indicates whether a key was pressed.
; If a key was pressed, the key value will be in the A register.
;
; Modifies: flags, A
MONRDKEY:
CHRIN:
                PHX                    ; Save X.
                JSR     BUFFER_SIZE    ; Get the number of unread bytes in the buffer.
                BEQ     @no_keypressed ; If no bytes, jump to no_keypressed.
                JSR     READ_BUFFER    ; Read a character from the buffer into A.
                JSR     CHROUT         ; Echo character.
                PLX                    ; Restore X. 
                SEC 
                RTS                    ; Return from subroutine.
@no_keypressed:
                PLX                    ; Restore X.
                CLC
                RTS                    ; No key pressed, return with C=0.


; Output a character to the serial interface from the A register.
; Modifies: flags, A
MONCOUT:
CHROUT:
                PHA                    ; Save A.
                STA     ACIA_DATA      ; Output character.
                LDA     #$FF           ; Initialize delay loop.
txdelay:        DEC                    ; Decrement A.
                BNE     txdelay        ; Until A gets to 0.
                PLA                    ; Restore A.
                RTS                    ; Return.

; Initialise the circular buffer.
; Modifies: flags, A
INIT_BUFFER:
                LDA     READ_PTR       ; Take whatever is in the read pointer and load to A
                STA     WRITE_PTR      ; Store the same value to the write pointer.
                RTS                    ; Return from subroutine.

; Write a character (from the A register) to the circular buffer.
; Modifies: flags, X
WRITE_BUFFER:
                LDX     WRITE_PTR      ; Load the write pointer into X.
                STA     INPUT_BUFFER,X ; Store the character in the buffer at the write pointer.
                INC     WRITE_PTR      ; Increment the write pointer.
                RTS                    ; Return from subroutine.

; Read a character from the circular buffer and put it in a the A register.
; Modifies: flags, A, X
READ_BUFFER:
                LDX     READ_PTR       ; Load the read pointer into X.
                LDA     INPUT_BUFFER,X ; Load the character from the buffer at the read pointer.
                INC     READ_PTR       ; Increment the read pointer.
                RTS                    ; Return from subroutine.

; Return (in the A register) the number of unread bytes in the circular buffer.
; Modifies: flags, A
BUFFER_SIZE:
                LDA     WRITE_PTR      ; Load the write pointer into A.
                SEC                    ; Set carry for subtraction.
                SBC     READ_PTR       ; Subtract the read pointer from the write pointer.
                RTS                    ; Return with the number of unread bytes in A.