ISCNTC:
    JSR MONRDKEY        ; Read a key from the serial interface.
    BCC not_cntc        ; If no key pressed, branch to not_cntc.
    CMP #3              ; Compare the key with ASCII 3 (CNTRL + C).   
    BNE not_cntc        ; If key is not ASCII 3, branch to not_cntc.
    JMP is_cntc         ; If key is ASCII 3, branch to is_cntc.

not_cntc:
    RTS

is_cntc:
                        ; Fall through