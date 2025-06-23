PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)

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

  lda #"H"          ; Output "H" to display
  jsr print_char
  lda #"e"          ; Output "e" to display
  jsr print_char
  lda #"l"          ; Output "l" to display
  jsr print_char
  lda #"l"          ; Output "l" to display
  jsr print_char
  lda #"o"          ; Output "o" to display
  jsr print_char
  lda #","          ; Output "," to display
  jsr print_char
  lda #" "          ; Output " " to display
  jsr print_char
  lda #"w"          ; Output "w" to display
  jsr print_char
  lda #"o"          ; Output "o" to display
  jsr print_char
  lda #"r"          ; Output "r" to display
  jsr print_char
  lda #"l"          ; Output "l" to display
  jsr print_char
  lda #"d"          ; Output "d" to display
  jsr print_char
  lda #"!"          ; Output "!" to display
  jsr print_char

loop:
  jmp loop

lcd_instruction:
  sta PORTB         ; Write command in a-register to Port B
  lda #0            ; Clear RS/RW/E bits
  sta PORTA
  lda #E            ; Set 'Enable' to so send instruction
  sta PORTA
  lda #0            ; Clear RS/RW/E bits
  sta PORTA
  rts               ; Return from Subroutine

print_char:
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
