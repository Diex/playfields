; S01E02 Generating a stable screen

; This example creates the proper VSYNC, and number of scanlines to generate a stable frame on NTSC
; televisions.

; This Episode on Youtube - https://youtu.be/WcRtIpvjKNI

; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

; Email - 8blit0@gmail.com

	processor 6502
	include "vcs.h"
	include "macro.h"

BLUE           = $9a         ;              define symbol for TIA color (NTSC)

        seg.u	vars		; uninitialized segment
        org	$80             ; origin set at base of ram

r_seed             ds 1            ; ball x pos
fcount              ds 1            ; frame counter

	
    seg code
	org $f000

reset:
	
    CLEAN_START

    ; generate a random see from the interval timer
    lda INTIM               ; unknown value to use as an initial random seed
    sta r_seed              ; random seed

clear:                       ;              define a label 
	lda #BLUE                ;              load the value from the symbol 'blue' into (a)
	sta COLUBK               ;              store (a) into the TIA background color register

startFrame:
    inc fcount              ;              increment the frame counter
	; start of new frame
	; start of vertical blank processing
	lda #0                   ;              load the value 0 into (a)
	sta VBLANK               ;              store (a) into the TIA VBLANK register
	lda #2                   ;              load the value 2 into (a). 
	sta VSYNC                ;              store (a) into TIA VSYNC register to turn on vsync
	sta WSYNC                ;              write any value to TIA WSYNC register to wait for hsync
;---------------------------------------
	sta WSYNC
;---------------------------------------
	sta WSYNC                ;              we need 3 scanlines of VSYNC for a stable frame
;---------------------------------------
	lda #0
	sta VSYNC                ;              store 0 into TIA VSYNC register to turn off vsync

	; generate 37 scanlines of vertical blank
	ldx #0
verticalBlank:   
	sta WSYNC                ;              write any value to TIA WSYNC register to wait for hsync
;---------------------------------------
	inx
	cpx #37                  ;              compare the value in (x) to the immeadiate value of 37
	bne verticalBlank        ;              branch to 'verticalBlank' label if compare not equal

	; generate 192 lines of playfield
    ; jsr galois_lfsr_random
    
    lda r_seed
    sta COLUBK

	ldx #0
playfield:
    
    sta WSYNC    
	inx
	cpx #192                 ;              compare the value in (x) to the immeadiate value of 192
	bne playfield            ;              branch to 'drawField' label if compare not equal

	; end of playfield - turn on vertical blank
    lda #%01000010
    sta VBLANK

	; generate 30 scanlines of overscan
	ldx #0
overscan:        
	sta WSYNC
;---------------------------------------
	inx
	cpx #30                  ;              compare value in (x) to immeadiate value of 30
	bne overscan             ;              branch up to 'overscan' label, compare if not equal
    jsr galois_lfsr_random
	jmp startFrame           ;              frame completed, branch up to the 'startFrame' label
;------------------------------------------------


; Galois 8-bit Linear Feedback Shift Registers
; https://samiam.org/blog/20130617.html
galois_lfsr_random:              
        lda r_seed              ; keep calling funtion to for better entropy
        lsr                     ; shift right
        bcc noeor0              ; if carry 1, then exclusive OR the bits
        eor #$D4                ; d4 tap (11010100)
noeor0: sta r_seed
        rts



	org $fffa                ;              set origin to last 6 bytes of 4k rom
	
interruptVectors:
	.word reset              ;              nmi
	.word reset              ;              reset
	.word reset              ;              irq
