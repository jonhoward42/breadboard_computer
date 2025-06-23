PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)
IFR   = $600d       ; W65C22S Interrupt Flag Register address
IER   = $600e       ; W65C22S Interrupt Enable Register address

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

  ldx #0            ; Set x-register to 0 (our loop counter)

print:
  lda message,x     ; Load digit 'x' from message into a-register
  beq loop          ; Branch to loop if zero flag is in a-register (end of message)
  jsr print_char    ; Print from a-register
  inx               ; Increment x-register by 1
  jmp print         ; Jump to top of print subroutine

message: .asciiz "Hello, world!                           Anybody there?"

loop:
  jmp loop
  
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
