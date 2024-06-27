                processor 6502		; -----------------------------------------------------
                include	 "vcs.h"	;
                include  "macro.h"	; 
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/KJYeQjJTkj4
                        	        ; Email - 8blit0@gmail.com
                                    ;
                                    ; PIA off the shelf 6532 Peripheral Interface Adaptor
                                    ; Programmable timers, 128 bytes RAM
                                    ; Two 8-bit parallel I/O ports
                                    ;
                                    ; PIA uses the same clock as 6502. 1 PIA cycle per 1 Machine Cycle.
                                    ; Can be set to 1 of 4 counting intervals. 1, 8, 64, 1024
                                    ; Select how many intervals from 1 to 255.
                                    ; Valu decrements at each interval
                                    ;
                                    ; write value to the desired interval setting
                                    ; 1 clock   TIM1T
                                    ; 8 clocks  TIM8T
                                    ; 64 clocks TIM64T
                                    ; 1024 clocks T1024T
                                    ;
                                    ; Read the timers after loaded at INTIM
                                    ;
                                    ; When it reaches 0, it will hold 0 for one interval, then the counter will flip to FF and decrements
                                    ; each clock cycle to allow the programmer determine how long ago the timer zeroed out.


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

                ; lda #0	            ; (2) set D1 to 0 to end VBLANK
                ; sta WSYNC           ; (3) wait for end of scanline                    
                ; sta COLUBK          ;(3)
                ; ldy #PF_H

; -------- wait ------------------------------------                                
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                    
; -------- done ------------------------------------
                lda #0
                sta WSYNC
                sta VBLANK
                
                
                ldy #PF_H
kernel:		    sta WSYNC           ; no lo cuento en la snl       		            

                sty temp            ; (3)
                
                lda temp            ; (3)
                sta COLUBK          ;(3)                
                sleep 4             ; (4)
                
                sta COLUBK          ;(3)                
                rol                 ; (2)
                sleep 4             ; (4)

                sta COLUBK          ;(3)                
                rol                 ; (2)
                sleep 4             ; (4)

                sta COLUBK          ;(3)                
                rol                 ; (2)
                sleep 4             ; (4)

                sta COLUBK          ;(3)                
                rol                 ; (2)
                sleep 4             ; (4)

                sta COLUBK          ;(3)                
                rol                 ; (2)
                sleep 4             ; (4)


                sta COLUBK          ;(3)                
                ; ror                 ; (2)
                

                nop                 ; (2)
                nop                 ; (2)
                
                
                

                dey                 ; (2)
                bne kernel          ; (3) 2 bytes del opcode (beq) + 1 byte operando + byte del salto
                
; --------------- DoneWithFrame	---------------
                                    ;clear out the playfield registers for obvious reasons	
                ; ---- Overscan (30 scanlines)
                ; 30 scanlines x 76 machine cycles = 2280 machine cycles
                ; 2280 machine cycles / 64 clocks = 35.625

                lda #35             ; We'll round down, and clean up the remaining cycles with a WSYNC
                sta TIM64T          ; Set a count of 35 with 64-clock interval

                lda #0
                sta PF2             
                sta PF0
                sta PF1

                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam                
               
                ; lda #0
                ; sta COLUBK


; -------- wait ------------------------------------
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                                    
; -------- done ------------------------------------
                
                jmp nextframe       ; (3) jump back up to start the next frame


                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)










