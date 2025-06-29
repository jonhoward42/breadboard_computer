# Assembler & Linker Commands used in this section
## Assembler
ca65 "bios.s"

## Linker
ld65 -C bios.cfg "bios.o" -Ln bios.sym