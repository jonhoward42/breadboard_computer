.segment "CODE"
.ifdef EATER
T1CL    = $6004             ; W65C22S Timer 1 (Counter Low)  Control Register address
T1CH    = $6005             ; W65C22S Timer 1 (Counter High) Control Register address
ACR     = $600B             ; W65C22S Timer 1 (Aux Control Register) Control Register address

BEEP:
        jsr FRMEVL          ; Evaluate the formula
        jsr MKINT           ; Parse a 16-bit integer

        ; Check if parameter is zero
        lda FAC+4           ; Load the high byte of the frequency
        ora FAC+3           ; OR with the low byte of the frequency
        beq @silent

        ; Set T1 timer with parameter
        lda FAC+4           ; Load the low byte of the frequency
        sta T1CL            ; Store it in Timer 1 Counter Low
        lda FAC+3           ; Load the high byte of the frequency
        sta T1CH            ; Store it in Timer 1 Counter High  

        ; Start square wave on PB7
        lda #$c0            ; Set Timer 1 Control Register to enable the timer
        sta ACR             ; Write to the Auxiliary Control Register

@silent:
        jsr CHKCOM          ; Check for a comma
        jsr GETBYT          ; Get the next byte (duration) 0-255 and put in X-Register
        cpx #0              ; Compare X-Register with zero
        beq @done           ; If zero, skip the delay

@delay1:
        ldy #$ff             ; Load Y-Register with a delay value (255)
@delay2:
        nop                 ; No operation (NOP) to create a delay
        nop                 ; No operation (NOP) to create a delay
        dey                 ; Decrement Y-Register
        bne @delay2         ; Loop until Y-Register is zero
        dex                 ; Decrement X-Register
        bne @delay1         ; Loop until X-Register is zero

        ; Stop square wave on PB7
        lda #0              ; Set Timer 1 Control Register to disable the timer
        sta ACR             ; Write to the Auxiliary Control Register

@done:
        rts                 ; Return from subroutine

.endif