PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)
IFR   = $600d       ; W65C22S Interrupt Flag Register address
IER   = $600e       ; W65C22S Interrupt Enable Register address

E     = %01000000   ; 'Enable' pin          = pin #2 (Port B)
RW    = %00100000   ; 'Read/Write' pin      = pin #3 (Port B)
RS    = %00010000   ; 'Register Select' pin = pin #4 (Port B)

  .org $8000

reset:
  ldx #$ff          ; Initialize Stack Registers (Load ff into x register)
  txs               ; Transfer X-to-S 

  lda #%00000000    ; Set W65C22S all pins (on port A) to input
  sta DDRA          ; Write above config data to DDRA

  lda #%11111111    ; Set W65C22S all pins (on port B) to output
  sta DDRB          ; Write above config data to DDRB

  jsr lcd_init
  lda #%00101000    ; Set Display 4-bit mode, 2-line display, 5x8 font
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
  lda #%11110000    ; Temporarily set LCD data to 'input'
  sta DDRB          ; Write 'input' to Port B data direction
lcd_busy:           ; https://gist.github.com/TheMagicNacho/caa694f45e25e249199fd46570cde147 
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
  rts

lcd_init:
  lda #%00000010     ; Set 4-bit mode
  sta PORTB          ; Write to Port B
  ora #E             ; Set 'Enable'
  sta PORTB          ; Write to Port B
  and #%00001111     ; ??? Not sure about this ???
  sta PORTB          ; Write to Port B
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  pha
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  rts

  .org $fffc
  .word reset
  .word $0000
