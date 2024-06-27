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

my16bit_lsb     ds 1                ; 1 byte - 16 bit counter lsb
my16bit_msb     ds 1                ; 1 byte - 16 bit counter msb
scanline        ds 1                ; 1 byte - current scanline
fcount          ds 1                ; 1 byte - frame counter

                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

nextframe:		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines
; -------- set timer -------------------------------
                                    ; 37 scanlines x 76 machine cycles per scanline = 2812 machine cycles
                                    ; 2812 machine cycles / 64 clocks = 43.9375
                lda #44             ; We'll round down, and clean up the remaining cycles with a WSYNC
                sta TIM64T          ; Set a count of 43 with 64-clock interval
; -------- do stuff  -------------------------------

                jsr add

; -------- wait ------------------------------------                                
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                    
; -------- done ------------------------------------
                
                lda #0
                sta WSYNC           ; primera linea visible
                sta VBLANK
                
                
                lda #PF_H
                sta scanline       ; 1 byte - current scanline

kernel:		    sta WSYNC           ; no lo cuento en la snl       		            

                
                ; lda scanline
                ; cmp my16bit_lsb
                
                lda scanline
                adc my16bit_lsb
                sta COLUBK          ;(3)
                
                
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

add	            clc		
                lda my16bit_lsb
                adc #1
                sta my16bit_lsb
                bcc ok             
                inc my16bit_msb
ok
                rts


                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)










