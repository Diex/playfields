                processor 6502		; -----------------------------------------------------
                include	 "vcs.h"	;
                include  "macro.h"	; 
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/KJYeQjJTkj4
                        	        ; Email - 8blit0@gmail.com
     
                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ 192            ; playfield height
                
                seg.u	temp		; uninitialized segment
                org	$80             ; origin set at base of ram
                ; 16 bytes of uninitialized memory
temp            ds 1                
                seg.u	vars		; uninitialized segment
                org	$90             ; origin set at base of ram

c16_1     ds 3                ; 1 byte - 16 bit counter lsb

scanline        ds 1                ; 1 byte - current scanline
fcount          ds 1                ; 1 byte - frame counter
t_               ds 2                ; 1 byte - temp
mod_1           ds 1                ; 1 byte - modulo 1

                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                lda #1
                sta CTRLPF

                lda #0	            ; (2) set D1 to 0 to end VBLANK
                sta c16_1,1
                sta c16_1
                
                lda #$1E
                sta COLUPF          

nextframe:		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines
; -------- set timer -------------------------------
                                    ; 37 scanlines x 76 machine cycles per scanline = 2812 machine cycles
                                    ; 2812 machine cycles / 64 clocks = 43.9375
                lda #44             ; We'll round down, and clean up the remaining cycles with a WSYNC
                sta TIM64T          ; Set a count of 43 with 64-clock interval
; -------- do stuff  -------------------------------
                ; jsr add
                ; jsr add
                ; jsr add
                ; jsr add
                jsr inc16_1

; -------- wait ------------------------------------                                
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                    
; -------- done ------------------------------------
                
                lda #0
                
                sta VBLANK
                
                
                lda #PF_H
                sta scanline       ; 1 byte - current scanline
                
                
                
                sta WSYNC           ; primera linea visible
                lda c16_1,1
                sta COLUPF
kernel:		    
                sta WSYNC           ; no lo cuento en la snl  
                
                
                
                jsr bytebeat2

                lda t_                
                sta PF1

                lda t_,1                
                sta PF2

                ; lda c16_1,1
                ; sta COLUBK          ;(3)
                
                dec scanline                 ; (2)
                bne kernel          ; (3) 2 bytes del opcode (beq) + 1 byte operando + byte del salto
                
; --------------- DoneWithFrame	---------------
                                    
                ; ---- Overscan (30 scanlines)
                ; 30 scanlines x 76 machine cycles = 2280 machine cycles
                ; 2280 machine cycles / 64 clocks = 35.625
                lda #35             ; We'll round down, and clean up the remaining cycles with a WSYNC
                sta TIM64T          ; Set a count of 35 with 64-clock interval

                
               
            
                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam                
            
; -------- wait ------------------------------------
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                                    
; -------- done ------------------------------------
                
                jmp nextframe       ; (3) jump back up to start the next frame

inc16_1	        clc		
                lda c16_1,1
                adc #1
                sta c16_1,1
                bcc ok             
                inc c16_1
ok
                rts


bytebeat2       clc
                lda c16_1,1 
                adc scanline
                bcc next
                inc c16_1
next                
                lsr t_,1    
                ; ora t_,1
                sta t_,1
                ; asl t_,1
                ; ora t_,1           
                
                
                lsr t_    
                ; ora t_
                sta t_
                ; asl t_
                ; ora t_           
                
                ; ror t_                
                
                inc t_
                
                rts


bytebeat
                lda t_
                ror
                ror
                ora t_
                ror
                ror
                ora t_
                and #$3F
                ror
                ror
                and t_
                rts

                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)










