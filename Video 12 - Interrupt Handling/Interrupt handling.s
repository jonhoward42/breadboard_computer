PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)
PCR   = $600c       ; W65C22S Periperhal Control Register address
IFR   = $600d       ; W65C22S Interrupt Flag Register address
IER   = $600e       ; W65C22S Interrupt Enable Register address

value = $0200       ; 2 bytes
mod10 = $0202       ; 2 bytes
message = $0204     ; 6 bytes
counter = $020a     ; 2 bytes

E     = %10000000   ; 'Enable' pin          = pin #1 (Port B)
RW    = %01000000   ; 'Read/Write' pin      = pin #2 (Port B)
RS    = %00100000   ; 'Register Select' pin = pin #3 (Port B)

  .org $8000

reset:
  ldx #$ff          ; Initialize Stack Register (Load ff into x register)
  txs               ; Transfer X-to-S
  cli               ; Clear interrupt disable bit
  
  lda #$82          ; Set W65C22S 'enable CA1' ('82' hex = 'enable CA1')
  sta IER           ; Write above config data to IER
  lda #$00          ; Set W65C22S 'CA1' PCR to 'falling edge' trigger
  sta PCR           ; Write above config data to PCR

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
  sta counter       ; Initialise 1st 8 bits of counter to 0
  sta counter + 1   ; Initialise 2nd 8 bits of counter to 0

loop:
  lda #%00000010    ; Change LCD to home position
  jsr lcd_instruction
  
  lda #0
  sta message
  
  ; Initialise 'value' to be the number to convert
  sei               ; Set interrupt disenable bit
  lda counter       ; Load 1st 8-bits (byte) of 'number' in a-register
  sta value         ; Store a-register into 1st 8-bits of 'value'
  lda counter + 1   ; Load 2nd 8-bits (byte) of 'number' in a-register
  sta value + 1     ; Store a-register into 2nd 8-bits of 'value'
  cli               ; Clear interrupt disenable bit
  
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

nmi:
irq:
  ; Maintain the contents of a, x & y registers during debounce loop
  pha               ; Push a-register to the stack
  txa               ; Transfer x- to a-register
  pha               ; Push a-register to the stack
  tya               ; Transfer y- to a-register
  pha               ; Push a-register to the stack

  inc counter
  bne exit_irq
  inc counter + 1
exit_irq:

  ldy #$ff
  ldx #$ff
delay:
  dex
  bne delay
  dey
  bne delay
  
  bit PORTA         ; Read W65C22S PORTA, which clears CA1 IRQ flag

  ; Reinstate the contents of a, x & y registers after debounce loop
  pla               ; Pull from the stack to a-register
  tay               ; Transfer a- to y-register
  pla               ; Pull from the stack to a-register
  tax               ; Transfer a- to x-register
  pla               ; Pull from the stack to a-register
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
