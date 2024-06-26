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
PF_H            equ #192            ; playfield height
CHANGE_T        equ 6     ; frames to change color
DATA_LENGTH     equ 96
                
                seg.u	temp		; uninitialized segment
                org	$80             ; origin set at base of ram
                ; 16 bytes of uninitialized memory
                
                seg.u	vars		; uninitialized segment
                org	$90             ; origin set at base of ram

scanline        ds 1                ; 1 byte - current scanline
; count1     ds 1                ; 1 byte - change color counter
colorbk         ds 1                ; 1 byte - background color
r_seed          ds 1                ; 1 byte - random seed
fcount          ds 1                ; 1 byte - frame counter
t_              ds 1                ; 1 byte - temp
t2_             ds 1                ; 1 byte - temp
temp            ds 1                ; 1 byte - temp
data            ds 96            ; 48 bytes - data


                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                ; lda #$1E
                ; sta COLUP0          ; set the P0 color 

                ; lda #$A8       
                ; sta COLUBK               

                ; lda #CHANGE_T
                ; sta count1

                ; lda INTIM
                ; sta r_seed

                ; lda #0
                ; sta fcount


nextframe:		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines

                ; 37 scanlines x 76 machine cycles per scanline = 2812 machine cycles
                ; 2812 machine cycles / 64 clocks = 43.9375
                ldx #44             ; We'll round down, and clean up the remaining cycles with a WSYNC
                stx TIM64T          ; Set a count of 43 with 64-clock interval

                ; do initializations
                lda #PF_H		    ; (2)
                sta scanline        ; (3)

                ; lda #0              ; background clear
                ; sta COLUBK

                ; lda #$FF
                ; sta COLUPF
                
                
                ; lda #%00000000
                ; sta CTRLPF           ; enable playfield                
                

                
                ; dec count1
                ; bne wait1

                ; lda #CHANGE_T    ; resets the color change counter
                ; sta count1                 
setPFColors:    
                ; lda		r_seed			
				; sta		COLUPF			; Set the PF color

                ; generate data:
                ; jsr randomData
                ; jsr bytebeat1
                ; jsr bytebeat2



wait1:          ldx INTIM           ; check the timer          
                bne wait1          ; if it's not 0 then branch back up to timer1
                
                lda #0	            ; (2) set D1 to 0 to end VBLANK
                sta	WSYNC		    ; (3) end with a clean scanline
                sta VBLANK		    ; (3) turn on the beam



                ; ldx #32
                ldy #192

kernel:		           	
	            sta WSYNC           ; no lo cuento en la snl
                ; background
                ; jsr background      ; 18   

                ; lda data,x          ; 4
                ; sta PF0             ; 3
                
                ; lda data,x          ; 4             
                ; sta PF1             ; 3
                
                ; lda data,x          ; 4         
                ; sta PF2             ; 3
                
                ; 39 cycles begginning to draw pf
                                
                ; lda #%0             ; 2
                ; sta PF0             ; 3
                ; ; 44
                ; sta PF1             ; 3
                ; ; 47
                ; nop                ; 2  
                ; nop                 ; 2
                ; nop                 ; 2
            ; 53
                
                dey     ; 5
                bne next ; 3     
                ;     ldy #6  ; 2
                ;     dex ; 5
                beq DoneWithFrame ; 3
next	         
                jmp kernel ;loop back up to draw the next pixel

DoneWithFrame	
	
                inc fcount
                ;clear out the playfield registers for obvious reasons	
                lda #0
                sta PF2 ;clear out PF2 first, I found out through experience
                sta PF0
                sta PF1

                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam

                ; ---- Overscan (30 scanlines)
                ; 30 scanlines x 76 machine cycles = 2280 machine cycles
                ; 2280 machine cycles / 64 clocks = 35.625

                ldx #35             ; We'll round down, and clean up the remaining cycles with a WSYNC
                stx TIM64T          ; Set a count of 35 with 64-clock interval

                lda #0              ; background clear
                sta COLUBK

timer2:         ldx INTIM
                bne timer2
                
                jmp nextframe       ; (3) jump back up to start the next frame

background:
                    lda fcount     ; 2
                    ; stx $80                                     
                    ; adc $80
                    sta COLUBK     ; 3
                    rts            ; 6
; ////////////////////////////////////////////////////////
randomData:                    
                ldx #DATA_LENGTH
galois_lfsr_random:              
                lda r_seed              ; keep calling funtion to for better entropy
                lsr                     ; shift right
                bcc noeor0              ; if carry 1, then exclusive OR the bits
                eor #$D4                ; d4 tap (11010100)
noeor0:         sta r_seed
                sta data,X
                dex
                bne galois_lfsr_random
                rts


bytebeat1:                
                lda t_                
                ldx #DATA_LENGTH
compute:
                ; ror
                adc #1
                ; eor #$d4
                ; sta temp
                ; lda t_
                ; ; REPEAT 3 ;
                ;     rol
                ;     rol
                ;     rol
                ; ; REPEND
                ; ora t_                            
                
                sta data,x                
                dex                
                bne compute
                    inc t_
                rts



                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)










