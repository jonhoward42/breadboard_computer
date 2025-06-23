PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)
ACR   = $600b
PCR   = $600c       ; W65C22S Periperhal Control Register address
IFR   = $600d       ; W65C22S Interrupt Flag Register address
IER   = $600e       ; W65C22S Interrupt Enable Register address

E     = %10000000   ; 'Enable' pin          = pin #1 (Port B)
RW    = %01000000   ; 'Read/Write' pin      = pin #2 (Port B)
RS    = %00100000   ; 'Register Select' pin = pin #3 (Port B)

ACIA_DATA   = $5000 ; W65C51S Data Register Address
ACIA_STATUS = $5001 ; W65C51S Status Register Address
ACIA_CMD    = $5002 ; W65C51S Command Register Address
ACIA_CTRL   = $5003 ; W65C51S Control Register Address

  .org $8000

reset:
  ; ===================================================================================
  ; Initialise Stack Register
  ; ===================================================================================
  ldx #$ff          ; Initialize Stack Register (Load ff into x register)
  txs               ; Transfer X-to-S
  
  ; ===================================================================================
  ; Initialise W65C22S VIA 
  ; ===================================================================================
  lda #%11100000    ; Set W65C22S first 3 pins (on port A) to output & other to input
  sta DDRA          ; Write above config data to DDRA
  lda #%11111111    ; Set W65C22S all pins (on port B) to output
  sta DDRB          ; Write above config data to DDRB

  ; ===================================================================================
  ; Initialise LCD Display 
  ; ===================================================================================
  lda #%00111000    ; Set Display 8-bit mode, 2-line display, 5x8 font 
  jsr lcd_instruction
  lda #%00001110    ; Set Display on, Curson on, Blink off
  jsr lcd_instruction
  lda #%00000110    ; Increment and shift cursor, Don't shift display
  jsr lcd_instruction
  lda #%00000001    ; Clear entire display
  jsr lcd_instruction

  ; ===================================================================================
  ; Initialise W65C51S ACIA / UART
  ; ===================================================================================
  lda #$00          ; An arbirary value to be sent to the ACIA status register
  sta ACIA_STATUS   ; Soft reset ACIA (Value not important)
  lda #$1f          ; 8-N-1, 19200 BAUD
  sta ACIA_CTRL     ; Set above to ACIA control register
  lda #$0b          ; No parity, no echo, no interrupts
  sta ACIA_CMD      ; Set about to ACIA command register

  ldx #0
send_msg:
  lda message,x
  beq done
  jsr send_char
  inx
  jmp send_msg
done:

rx_wait:
  lda ACIA_STATUS   ; Load ACIA Status register into A-register
  and #$08          ; Check RX buffer status flag
  beq rx_wait       ; Loop if RX buffer is empty
  lda ACIA_DATA
  jsr print_char    ; Print received character to the LCD
  jsr send_char     ; Echo received character back over serial interface
  jmp rx_wait

message: .asciiz "Jon's 6502 Breadboard Computer"

send_char:
  sta ACIA_DATA     ; Send A-register back to ACIA data register
  pha               ; Push A-register onto the stack
tx_wait:
  lda ACIA_STATUS   ; Load ACIA Status register into A-Register
  and #$10          ; Check TX buffer status flag
  beq tx_wait       ; Loop if TX buffer is not empty
  jsr tx_delay      ; Introduce a delay to accomodate ACIA hardware bug
  pla               ; Pull A-register value back from the stack
  rts

tx_delay:
  phx
  ldx #100
tx_delay_1:
  dex
  bne tx_delay_1
  plx
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
  pha               ; Push A-Register onto the stack (preserving the character data)
  lda #RS           ; Set 'Register Select', Clear 'Read/Write' & 'Enable'
  sta PORTA
  lda #(RS | E)     ; Set 'Register Select' AND 'Enable'
  sta PORTA
  lda #RS           ; Set 'Register Select', Clear 'Read/Write' & 'Enable'
  sta PORTA
  pla               ; Pull character data from the stack back into the A-register
  rts               ; Return from Subroutine

  .org $fffc
  .word reset
  .word $0000
