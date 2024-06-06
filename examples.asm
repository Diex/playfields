; Random Byte Generator for 6502
LDA #<random
STA $FFFC
LDA #>random
STA $FFFD

; Generate random byte
JSR $FFFC

; Store the random byte in memory location $C000
STA $C000

; End of program
BRK

random:
    LDA $FB
    ADC $FB
    STA $FB
    RTS


random:
; Initialize random seed
LDA #0
STA $FB

; Generate random byte
JSR RANDOM_BYTE

; Store the random byte in memory location $C000
STA $C000

; End of program
BRK

; Subroutine to generate a random byte
RANDOM_BYTE:
    LDA $FB
    ADC $FB
    STA $FB
    RTS