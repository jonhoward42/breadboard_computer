.segment "CODE"
.ifdef EATER

PORTB = $6000             ; W65C22S Port B address
DDRB  = $6002             ; W65C22S Data Direction Register address (Port B)
E     = %01000000         ; 'Enable' pin          = pin #2 (Port B)
RW    = %00100000         ; 'Read/Write' pin      = pin #3 (Port B)
RS    = %00010000         ; 'Register Select' pin = pin #4 (Port B)

lcd_wait:
        pha               ; Push a-register onto the stack (preserving previous data)
        lda #%11110000    ; Temporarily set LCD data to 'input'
        sta DDRB          ; Write 'input' to Port B data direction
lcd_busy:            
        lda #RW           ; Load RW into a-register
        sta PORTB         ; Write RW to Port B
        lda #(RW | E)     ; Load RW & Enable to a-register
        sta PORTB         ; Write RW & Enable to Port B
        lda PORTB         ; Load high nibble from Port B to a-register
        pha               ; Push a-register to the stack since it has the busy flag
        lda #RW           ; Load RW into a-register
        sta PORTB         ; Write RW to Port B
        lda #(RW | E)     ; Load RW & Enable to a-register
        sta PORTB         ; Write RW & Enable to Port B
        lda PORTB         ; Load low nibble from Port B to a-register
        pla               ; Pull high nibble from the stact
        and #%00001000
        bne lcd_busy
        lda #RW           ; Load RW in a-register (clearing the previous enable)
        sta PORTB         ; Write RW to Port B
        lda #%11111111    ; Re-set port to 'output'
        sta DDRB          ; Write 'output' to Port B data direction
        pla               ; Pull from the stack into a-register (preserving previous data)
        rts               ; Return from subroutine  

LCDINIT:
        lda #$ff          ; Set Port B to output
        sta DDRB          ; Write 'output' to Port B data direction

        lda #%00000011    ; Set 8-bit mode
        sta PORTB         ; Write to Port B
        ora #E            ; Set 'Enable'
        sta PORTB         ; Write to Port B
        and #%00001111    ; ??? Not sure about this ???
        sta PORTB         ; Write to Port B

        lda #%00000011    ; Set 8-bit mode
        sta PORTB         ; Write to Port B
        ora #E            ; Set 'Enable'
        sta PORTB         ; Write to Port B
        and #%00001111    ; ??? Not sure about this ???
        sta PORTB         ; Write to Port B

        lda #%00000011    ; Set 8-bit mode
        sta PORTB         ; Write to Port B
        ora #E            ; Set 'Enable'
        sta PORTB         ; Write to Port B
        and #%00001111    ; ??? Not sure about this ???
        sta PORTB         ; Write to Port B

        ; Okay, now we are really in 8-bit mode
        ; Command to get 4-bit mode ought to work now

        lda #%00000010    ; Set 4-bit mode
        sta PORTB         ; Write to Port B
        ora #E            ; Set 'Enable'
        sta PORTB         ; Write to Port B
        and #%00001111    ; ??? Not sure about this ???
        sta PORTB         ; Write to Port B

        lda #%00101000    ; Set Display 4-bit mode, 2-line display, 5x8 font
        jsr lcd_instruction
        lda #%00001110    ; Set Display on, Curson on, Blink off
        jsr lcd_instruction
        lda #%00000110    ; Increment and shift cursor, Don't shift display
        jsr lcd_instruction
        lda #%00000001    ; Clear entire display
        jsr lcd_instruction
        rts               ; Return from subroutine

LCDCMD:
        jsr GETBYT        ; Get byte from the input buffer and put into X-register
        txa               ; Transfer X-register to A-register
lcd_instruction:
        jsr lcd_wait      ; Wait for LCD to be ready
        pha               ; Push A-register onto the stack
        lsr               ; Shift right 4 times to get high 4 bits
        lsr               ;
        lsr               ;
        lsr               ;
        sta PORTB         ; Write high 4 bits to Port B
        ora #E            ; Set E bit to send instruction
        sta PORTB         ; Write to Port B
        eor #E            ; Clear E bit
        sta PORTB         ; Write to Port B
        pla               ; Pull A-register value back from the stack
        and #%00001111    ; Send low 4 bits
        sta PORTB         ; Write low 4 bits to Port B
        ora #E            ; Set E bit to send instruction
        sta PORTB         ; Write to Port B
        eor #E            ; Clear E bit
        sta PORTB         ; Write to Port B
        rts               ; Return from subroutine

LCDPRINT:
        jsr FRMEVL        ; Evaluate the frame and get the value
        bit VALTYP        ; Check if the value type is a string
        bmi lcd_print     ; If negative, it's a string, so jump to lcd_print
        jsr FOUT          ; Call FOUT to output the value
        jsr STRLIT        ; Process the string literal
lcd_print:
        jsr FREFAC        ; Get the last value from the frame
        tax               ; Transfer A-register to X-register
        ldy #0            ; Initialize Y-register to 0
lcd_print_loop:
        lda (INDEX),Y     ; Load character from the input buffer
        jsr lcd_print_char; Print the character to the LCD
        iny               ; Increment Y-register
        dex               ; Decrement X-register
        bne lcd_print_loop; Loop until all characters are printed
        rts               ; Return from subroutine

lcd_print_char:
        jsr lcd_wait      ; Wait for LCD to be ready
        pha               ; Push A-register onto the stack
        lsr               ; Shift right 4 times to get high 4 bits
        lsr               ;
        lsr               ;
        lsr               ;
        ora #RS           ; Set RS
        sta PORTB         ; Write high 4 bits to Port B
        ora #E            ; Set E bit to send instruction
        sta PORTB         ; Write to Port B
        eor #E            ; Clear E bit
        sta PORTB         ; Write to Port B
        pla               ; Pull A-register value back from the stack
        and #%00001111    ; Send low 4 bits
        ora #RS           ; Set RS
        sta PORTB         ; Write low 4 bits to Port B
        ora #E            ; Set E bit to send instruction
        sta PORTB         ; Write to Port B
        eor #E            ; Clear E bit
        sta PORTB         ; Write to Port B
        rts               ; Return from subroutine

LCDCLS:
        lda #%00000001    ; Clear entire display
        jsr lcd_instruction
        rts               ; Return from subroutine

.endif