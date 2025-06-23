PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)
IFR   = $600d       ; W65C22S Interrupt Flag Register address
IER   = $600e       ; W65C22S Interrupt Enable Register address

value = $0200       ; 2 bytes
mod10 = $0202       ; 2 bytes
message = $0204     ; 6 bytes

E     = %10000000   ; 'Enable' pin          = pin #1 (Port B)
RW    = %01000000   ; 'Read/Write' pin      = pin #2 (Port B)
RS    = %00100000   ; 'Register Select' pin = pin #3 (Port B)

  .org $8000

reset:
  ldx #$ff          ; Initialize Stack Registers (Load ff into x register)
  txs               ; Transfer X-to-S 

  lda #%11100000    ; Set W65C22S first 3 pins (on port A) to output & other to input
  sta DDRA          ; Write above config data to DDRA

  lda #%11111111    ; Set W65C22S all pins (on port B) to output
  sta DDRB          ; Write above config data to DDRB

  lda #%00111000    ; Set Display 8-bit mode, 2-line display, 5x8 font
  jsr lcd_instruction

  lda #%00001110    ; Set Display on, Curson on, Blink off
  jsr lcd_instruction

  lda #%00000110    ; Increment and shift cursor, Don't shift display
  jsr lcd_instruction

  lda #%00000001    ; Clear entire display
  jsr lcd_instruction

  lda #0
  sta message
  
  ; Initialise 'value' to be the number to convert
  lda number        ; Load 1st 8-bits (byte) of 'number' in a-register
  sta value         ; Store a-register into 1st 8-bits of 'value'
  lda number + 1    ; Load 2nd 8-bits (byte) of 'number' in a-register
  sta value + 1     ; Store a-register into 2nd 8-bits of 'value'
  
divide:
  ; Initialise the remainder to zero
  lda #0            ; Load zero into a-register
  sta mod10         ; Initialise 1st 8-bits of 'mod10' with a-register (zero)
  sta mod10 +1      ; Initialise 2nd 8-bits of 'mod10' with a-register (zero)
  clc               ; Clear the carry bit
  
  ldx #16           ; Initialise x-register to '16'
  
divloop:  
  ; Rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a- and y-registers = dividend - divisor
  sec
  lda mod10
  sbc #10
  tay                ; Save low byte in y-register
  lda mod10 + 1
  sbc #0
  bcc ignore_result  ; Branch if divident is less than divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex                ; Decrement x-register
  bne divloop        ; Branch back to divloop if x-register is not 0
  rol value          ; Shift in the last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"           ; Add a zero to convert to ASCII???
  jsr push_char      ; 'Push' the resultant character to the 'message' string
  
  ; if value != 0, then continue dividing
  lda value
  ora value + 1
  bne divide         ; Branch back to 'divide' if value != 0

  ldx #0            ; Set x-register to 0 (our loop counter)

print:
  lda message,x     ; Load digit 'x' from message into a-register
  beq loop          ; Branch to loop if zero flag is in a-register (end of message)
  jsr print_char    ; Print from a-register
  inx               ; Increment x-register by 1
  jmp print         ; Jump to top of print subroutine

loop:
  jmp loop

number: .word 1729

push_char:          ; Add the digit in the a-register to the beginning of 'message' string
  pha               ; Push first new digit onto the stack
  ldy #0            ; Initialise y-register to zero

char_loop:
  lda message,y     ; Get the yth digit from string
  tax               ; And put into x-register
  pla               ; Pull the new digit from the stack into the a-register
  sta message,y     ; And add it to the 'message' string
  iny               ; Increment y
  txa               ; Transfer from x-register to a-register
  pha               ; Push digit from string on the stack
  bne char_loop     ; Repeat this loop until a-register is 0
  
  pla
  sta message,y     ; Pull the null off the stack and add to the end of 'message' string
  
  rts

lcd_wait:
  pha               ; Push a-register onto the stack (preserving previous data)
  lda #%00000000    ; Temporarily set port to 'input'
  sta DDRB          ; Write 'input' to Port B data direction

lcd_busy:
  lda #RW           ; Load RW into a-register
  sta PORTA         ; Write RW to Port A
  lda #(RW | E)     ; Load RW & Enable to a-register
  sta PORTA         ; Write RW & Enable to Port A
  lda PORTB         ; Load data from Port A to a-register
  
  and #%10000000    ; bitwise AND with a-register/Port B (1=LCD busy, 0=LCD not busy)
  bne lcd_busy      ; Essentially 'branch if not "0"' (i.e. busy)
  
  lda #RW           ; Load RW in a-register (clearing the previous enable)
  sta PORTA         ; Write RW to Port A
  lda #%11111111    ; Re-set port to 'output'
  sta DDRB          ; Write 'output' to Port B data direction
  pla               ; Pull from the stack into a-register (preserving previous data)
  rts

lcd_instruction:
  jsr lcd_wait      ; Check if the LCD screen is busy
  sta PORTB         ; Write command in a-register to Port B
  lda #0            ; Clear RS/RW/E bits
  sta PORTA
  lda #E            ; Set 'Enable' to so send instruction
  sta PORTA
  lda #0            ; Clear RS/RW/E bits
  sta PORTA
  rts               ; Return from Subroutine

print_char:
  jsr lcd_wait      ; Check if the LCD screen is busy
  sta PORTB         ; Write data in a-register to Port B
  lda #RS           ; Set 'Register Select', Clear 'Read/Write' & 'Enable'
  sta PORTA
  lda #(RS | E)     ; Set 'Register Select' AND 'Enable'
  sta PORTA
  lda #RS           ; Set 'Register Select', Clear 'Read/Write' & 'Enable'
  sta PORTA
  rts               ; Return from Subroutine

  .org $fffc
  .word reset
  .word $0000
