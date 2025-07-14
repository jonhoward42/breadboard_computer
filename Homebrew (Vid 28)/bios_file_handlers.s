.segment "BIOS"

;Dummy file handlers for LOAD and SAVE.
;These are not implemented in this BIOS, but are required for compatibility with the BASIC interpreter.
LOAD:
    RTS

SAVE:
    RTS