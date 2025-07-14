# Homebrew code for my Breadboard computer
The code held here essentially mirrors that of Ben Eater's series (up to Video 28) but with a few modifications of my own:

1. BIOS reworked quite a lot to include code & definitions from other areas:
    - Register addresses now maintained in the BIOS code
    - Reset code (referenced by the reset vector) now held in the BIOS code - not within WOZMON
    - Dummy file handers moved to a separate file (bios_file_handlers.s) and included in the BIOS code
    - IRQ handler moved to a separate file (bios_irq_handler.s) and included in the BIOS code
    - Serial / UART code moved to a separate file (bios_serial.s) and included in the BIOS code

2. The new reset code (now in the BIOS) jumps to "COLD_START", immediately loading MS BASIC

3. Additional commands added to MS Basic:
    - LCDCLS    - Clears the LCD screen
    - WOZMON    - Jumpts to LOADWOZMON (now in the BIOS) and loads WOZMON from BASIC