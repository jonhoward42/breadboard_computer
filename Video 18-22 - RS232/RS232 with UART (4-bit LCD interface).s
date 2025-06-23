PORTA = $6001       ; W65C22S Port A address  
PORTB = $6000       ; W65C22S Port B address
DDRA  = $6003       ; W65C22S Data Direction Register address (Port A)
DDRB  = $6002       ; W65C22S Data Direction Register address (Port B)
ACR   = $600b
PCR   = $600c       ; W65C22S Periperhal Control Register address
IFR   = $600d       ; W65C22S Interrupt Flag Register address
IER   = $600e       ; W65C22S Interrupt Enable Register address

E     = %01000000   ; 'Enable' pin          = pin #2 (Port B)
RW    = %00100000   ; 'Read/Write' pin      = pin #3 (Port B)
RS    = %00010000   ; 'Register Select' pin = pin #4 (Port B)

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
  lda #%00000000    ; Set W65C22S all pins (on port A) to input
  sta DDRA          ; Write above config data to DDRA
  lda #%11111111    ; Set W65C22S all pins (on port B) to output
  sta DDRB          ; Write above config data to DDRB

  ; ===================================================================================
  ; Initialise LCD Display 
  ; ===================================================================================
  jsr lcd_init
  lda #%00101000    ; Set Display 4-bit mode, 2-line display, 5x8 font
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

; ===================================================================================
; Send an initial message over the serial interface
; ===================================================================================
  ldx #0            ; Load X register with 0 to start sending message
send_msg:
  lda message,x     ; Load character from message into A-register
  beq done          ; If end of message, jump to done
  jsr send_char     ; Send character to ACIA
  inx               ; Increment X register to point to next character
  jmp send_msg      ; Loop back to send next character
done:               ; End of message reached

; ===================================================================================
; Wait for characters from the serial interface, print them to the LCD,
; and echo them back over the serial interface
; ===================================================================================
rx_wait:
  lda ACIA_STATUS   ; Load ACIA Status register into A-register
  and #$08          ; Check RX buffer status flag
  beq rx_wait       ; Loop if RX buffer is empty
  lda ACIA_DATA
  jsr print_char    ; Print received character to the LCD
  jsr send_char     ; Echo received character back over serial interface
  jmp rx_wait

; ===================================================================================
; Startup message
; ===================================================================================
message: .asciiz "Jon's 6502 Breadboard Computer"

; ===================================================================================
; Send character to ACIA and wait for transmission to complete
; ===================================================================================
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

tx_delay:           ; Introduce a delay to accomodate ACIA hardware bug
  phx               ; Push X-register onto the stack
  ldx #100          ; Load X-register with 100 (arbitrary delay value)
tx_delay_1:         ; Loop to create a delay
  dex               ; Decrement X-register
  bne tx_delay_1    ; Branch if X-register is not zero
  plx               ; Pull X-register value back from the stack
  rts               ; Return from subroutine

; ===================================================================================
; LCD Functions
; ===================================================================================
lcd_wait:
  pha               ; Push a-register onto the stack (preserving previous data)
  lda #%11110000    ; Temporarily set LCD data to 'input'
  sta DDRB          ; Write 'input' to Port B data direction
                    ; ** Modified lcd_busy and lcd_init from
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
  lda #%00000010    ; Set 4-bit mode
  sta PORTB         ; Write to Port B
  ora #E            ; Set 'Enable'
  sta PORTB         ; Write to Port B
  and #%00001111    ; ??? Not sure about this ???
  sta PORTB         ; Write to Port B
  rts               ; Return from subroutine

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

print_char:
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
  pha               ; Push A-register onto the stack again
  and #%00001111    ; Send low 4 bits
  ora #RS           ; Set RS
  sta PORTB         ; Write low 4 bits to Port B
  ora #E            ; Set E bit to send instruction
  sta PORTB         ; Write to Port B
  eor #E            ; Clear E bit
  sta PORTB         ; Write to Port B
  pla               ; Pull A-register value back from the stack
  rts               ; Return from subroutine

; ===================================================================================
; End of program
; ===================================================================================
; The program ends here, and the reset vector points to the reset label.
; The reset vector is used by the CPU to start executing the program when it is powered
; on or reset. The program will start executing from the reset label, which initializes
; the stack, VIA, LCD, and ACIA, and then enters a loop
; ===================================================================================
  .org $fffc
  .word reset
  .word $0000
