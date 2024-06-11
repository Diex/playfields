				processor 6502			; s01e05 Ex1. Draw the playfield on an Atari 2600
				include	 "vcs.h"		; This example uses the TIA PF0, PF1, PF2, and CTLRPF 
										; Registers to draw a border around the screen. We're setting the top and
										; bottom border before and at the end of the main 192 screen frame which will result in
										; thicker than expected top and bottom boarders when executed in the 
										; Stella emulator because it shows the number of scanlines that could be displayed on some CRT's.
										; However, on most CRT's usually 192 (+/- a few) scanlines are visible so the thickness of the
										; boarder would look the same all around. For this, we're not even going to use VBLANK.
                                        ;
                                        ; This Episode on Youtube - https://youtu.be/LWIyHl9QfvQ
                                        ;
										; Become a Patron - https://patreon.com/8blit
										; 8blit Merch - https://8blit.myspreadshop.com/
										; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
										; Follow on Facebook - https://www.facebook.com/8Blit
										; Follow on Instagram - https://www.instagram.com/8blit
										; Visit the Website - https://www.8blit.com 
                                        ;
                                        ; Email - 8blit0@gmail.com


BORDERCOLOR		equ 	#$9A
BORDERHEIGHT	equ		#20				; How many scan lines are our top and bottom borders
SEGMENTS 		equ		#24

				; assigning RAM addresses to labels.
                seg.u	vars		; uninitialized segment
                org	$80             ; origin set at base of ram

framecount:	    ds	1				; frame counter
				; ------------------------- Start of main segment ---------------------------------

				seg   	code		; uninitialized segment
				org     $F000

				; ------------------------- Start of program execution ----------------------------


reset: 			ldx 	#0 				; Clear RAM and all TIA registers
                ldy 	#0
				lda 	#0 


clear:       	sta 	0,x 			; $0 to $7F (0-127) reserved OS page zero, $80 to $FF (128-255) user zero page ram.
				inx 
				bne 	clear

				lda 	#%00000001		; Set D0 to reflect the playfield
				sta 	CTRLPF			; Apply to the CTRLPF register

				lda		#BORDERCOLOR			
				sta		COLUPF			; Set the PF color
				lda 	#$46
				sta		COLUBK			; Set the background color


                ; generate a random see from the interval timer
                ; lda INTIM               ; unknown value to use as an initial random seed
                ; sta r_seed              ; random seed
                ; sta l_seed              ; iterive seed
				; sta RANDOM			  ; random number
				; --------------------------- Begin main loop -------------------------------------
				; 262 lineas x 288 clock counts
				; 3 vsync lines
				; 37 vertical blank lines
				; 192 drawfield lines
				; 30 overscan lines
				; --------------------------- 262 scanlines per frame -----------------------------
startframe:		
				; When the last line of the previous frame is detected, 
				; the microprocessor must generate 3 lines of VSYNC
				; When the electron beam has scanned 262 lines, 
				; the TV set must be signaled to blank the beam and position 
				; it at the top of the screen to start a new frame. 
				; This signal is called vertical sync, and the TIA must 
				; transmit this signal for at least 3 scan lines. 
				; This is accomplished by writing a “1” in D1 of VSYNC to turn 
				; it on, count at least 2 scan lines, then write a “0” to D1 of 
				; VSYNC to turn it off.
				lda 	#%00000010		; Writing a bit into the D1 vsync latch
				sta 	VSYNC 			; Turn on VSYNC
				; --------------------------- 3 scanlines of VSYNC signal
				sta 	WSYNC
				sta 	WSYNC
				sta 	WSYNC
				; --------------------------- Turn off VSYNC         	 
				lda 	#0
				sta		VSYNC
				; -------------------------- Additional 37 scanlines of vertical blank ------------

				lda    	#%11111111		; Solid line of pixels
				sta    	PF0				; Set them in all the PF# registers
				sta 	PF1
				sta    	PF2	
				ldx 	#0 					
				lda 	#0

lvblank:		sta 	WSYNC
				inx
				cpx 	#37				; 37 scanlines of vertical blank
				bne 	lvblank			; branch on not equal to continue the loop
				
				; --------------------------- 192 lines of drawfield ------------------------------
    			ldx 	#0 				; x = line number	                
walls:			sta 	WSYNC
    			inx  
				cpx 	#192	; will be interpreted by the assembler
				bne		walls		; branch on top down

				; -------------------------- 30 scanlines of overscan -----------------------------

				ldx 	#0					
overscan:       sta 	WSYNC
				inx
				cpx 	#30
				bne 	overscan

				; --------------------------- End of overscan -------------------------------------
                inc framecount
                lda framecount
                cmp #7
                beq changecolor

				jmp 	startframe		; jump back up to start the next frame


changecolor:	lda		COLUPF+1                
                sta		COLUPF
                lda     #0
                sta     framecount
                jmp		startframe

				; --------------------------- Pad until end of main segment -----------------------
                org 	$FFFA
irqvectors:
				.word reset          	; NMI
				.word reset          	; RESET
				.word reset          	; IRQ
                

				; -------------------------- End of main segment ----------------------------------