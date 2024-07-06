    MAC _CLR16 
        LDA #0
        STA {1}+0
        STA {1}+1
    ENDM



;              MAC VERTICAL_SYNC
;                 lda #%1110          ; each '1' bits generate a VSYNC ON line (bits 1..3)
; .VSLP1          sta WSYNC           ; 1st '0' bit resets Vsync, 2nd '0' bit exit loop
;                 sta VSYNC
;                 lsr
;                 bne .VSLP1          ; branch until VYSNC has been reset
;              ENDM