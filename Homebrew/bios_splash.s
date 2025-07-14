.segment "BIOS"

PRNT_LCD_SPLASH:
      LDA LCD_SPLASH1, x
      BEQ DONE_1
      JSR lcd_print_char
      INX
      JMP PRNT_LCD_SPLASH
DONE_1:
      LDX #0
      JSR LCDCR             ; Set cursor to home position, line 2

PRNT_LCD_SPLASH2:
      LDA LCD_SPLASH2, x
      BEQ DONE_2
      JSR lcd_print_char
      INX
      JMP PRNT_LCD_SPLASH2
DONE_2:
      LDX #0
    
      RTS