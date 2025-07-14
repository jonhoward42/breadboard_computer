.segment "BIOS"

; Interrupt request handler (currently only for ACIA RX interrupts).
IRQ_HANDLER:
                PHA                    ; Save A.
                PHX                    ; Save X.
                LDA     ACIA_STATUS    ; Check the ACIA status register (resetting the interrupt).
                LDA     ACIA_DATA      ; Read the data from the ACIA.
                JSR     WRITE_BUFFER   ; Write the character to the circular buffer.
                PLX                    ; Restore X.
                PLA                    ; Restore A.
                RTI                    ; Return from interrupt. 