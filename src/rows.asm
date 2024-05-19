
            processor 6502

            include "vcs.h"

            include "macro.h"



            SEG

            ORG $F000

Reset
            ldx #$80
            lda #0

ClearRAM

            sta 0,x
            inx
            bne ClearRAM


StartOfFrame

   ; Start of vertical blank processing
            ; lda #0
            ; see stella programmers guide
            ; https://www.alienbill.com/2600/101/docs/stella.html
            
            ; sta COLUBK

            ;This counter allows 160 color clocks for the beam to reach the right edge, 
            ; then generates a horizontal sync signal (HSYNC)  
            ; Therefore, one complete scan line of 228 color clocks allows only 
            ; 76 machine cycles (228/3 = 76) per scan line. 


            ; This is accomplished by writing a "1" in D1 of VSYNC to turn it on, 
            ; count at least 2 scan lines, then write a "0" to D1 of VSYNC to turn it off.
            lda #2            
            sta VSYNC

            sta WSYNC
            sta WSYNC
            sta WSYNC ; 3 to be safe
            
            lda #0
            sta VSYNC           



            ; 37 scanlines of vertical blank...
            
            ; In a raster scan display, the vertical blanking interval (VBI), 
            ; also known as the vertical interval or VBLANK, 
            ; is the time between the end of the final visible line of a frame or field[1] 
            ; and the beginning of the first visible line of the next frame or field. 
            ; It is present in analog television, VGA, DVI and other signals.
            
            ; This is accomplished by writing a "1" in D1 of VBLANK to turn it on, 
            ; count 37 lines, then write a "0" to D1 of VBLANK to turn it off. 

            lda #2
            sta VBLANK

            ldx #37
blanking
            stx WSYNC
            dex
            bne blanking

            lda #0
            sta VBLANK      ; end of screen - enter blanking

            

            ; 192 scanlines of picture...

            ldx #192    ; 192 lineas
            ldy #0      ; 0 color
                
line                  
            stx WSYNC    ; wait for end of scanline   

            stx COLUBK  ; del color x    
            dex 
            bne line

            
            ; The answer to the above question is that it depends on what the programmer
            ; does with the value, as in signed 8-bit arithmetic, %11111111 is -1, and in
            ; unsigned 8-bit arithmetic it is 255. 
            lda #%00000010  ; = 2
            sta VBLANK       ; end of screen - enter blanking
            ldx #30
overscan            
            stx WSYNC
            dex
            bne overscan
            
            lda #%0
            sta VBLANK       ; end of screen - enter blanking

            jmp StartOfFrame


            ; The two bytes for the 16-bit address where the interrupt-service routine (ISR) 
            ; for the non-maskable interrupt (NMI) go in FFFA-FFFB; 
            ; the reset gets FFFC-FFFD, 
            ; and the IRQ gets FFFE-FFFF
            ORG $FFFA
            .word Reset          ; NMI
            .word Reset          ; RESET
            .word Reset          ; IRQ



            END
