                processor 6502		; -----------------------------------------------------
                include	 "vcs.h"	;
                include  "macro.h"	; 
                include "macros2.h"
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/KJYeQjJTkj4
                        	        ; Email - 8blit0@gmail.com
     
                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ 192            ; playfield height
                
                seg.u	temp		; uninitialized segment
                org	$80             ; origin set at base of ram

                                    ; up to 9F
c16_1           ds 2

revbits         ds 2


                seg.u	vars		
                org	$A0             

temp            ds 4                
scanline        ds 1                ; 1 byte - current scanline
fcount          ds 1                ; 1 byte - frame counter
t_              ds 2                ; 1 byte - temp
mod_1           ds 1                ; 1 byte - modulo 1
speed           ds 1                ; 1 byte - speed
snd_on          ds 2            ; 1 byte per audio channel - greater than 0 if sound is playing       
                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                lda #1
                sta CTRLPF

                lda #$1E
                sta COLUPF          

                ; lda #255
                ; sta c24_1+1

nextframe:		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines
; -------- set timer -------------------------------
                                    ; 37 scanlines x 76 machine cycles per scanline = 2812 machine cycles
                                    ; 2812 machine cycles / 64 clocks = 43.9375
                lda #44             ; We'll round down, and clean up the remaining cycles with a WSYNC
                sta TIM64T          ; Set a count of 43 with 64-clock interval
; -------- do stuff  -------------------------------
                dec mod_1
                bne cont
                lda speed
                sta mod_1                
                _INC16 c16_1
cont
                jsr snd_process
; -------- wait ------------------------------------                                
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                    
; -------- done ------------------------------------
                
                lda #0
                
                sta VBLANK
                
                lda #PF_H
                sta scanline

              
                
                sta WSYNC           ; primera linea visible
                
          
        
                
                
render:		    sta WSYNC           ; no lo cuento en la snl  
                
                lda scanline
                ror                
                sta COLUPF
          

                jsr kernel1
                sta PF2
                dec scanline                 ; (2)



                sta WSYNC
                
                lda scanline
                ror                                             
                sta COLUPF
          
                ; jsr kernel2
                sta PF1
            
                
                dec scanline                 ; (2)
                bne render          ; (3) 2 bytes del opcode (beq) + 1 byte operando + byte del salto
                
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


kernel1:
                
                lda c16_1+1
                adc scanline
                rol
                sta temp
                lda c16_1+1
                rol
                eor temp
                sta temp
                
                lda c16_1+1
                ror
                ror
                ror
                ror
                ; ror
                adc temp                
                rts

kernel2:

                lda c16_1+0    
                adc scanline
                rol
                sta temp
                lda c16_1+0
                rol
                eor temp
                
                rts







reverseBits:
    tax
    lda reversedOrderBits,x      ; Load the value to be reversed from memory
    rts        


; cues a sound to play. sets audio registers based on table lookup sndbank.
; parameters: x = channel (0|1), y = sound to play
snd_play:
            ; lda sndbank_type,y
            lda #$0C
            sta AUDC0,x             ; audio control   
            
            lda #4
            sta AUDV0,x             ; audio volume (0 a 15)

            lda c16_1
            ror
            ror
            ror
            sta AUDF0,x             ; audio frequence (0 a 31 - divisiones del clock)
            
            lda #12
            sta snd_on,x            ; len of audio in frames (>0 = sound on)
        rts

; process sound channels to turn off volume when sound length counter runs out
snd_process:
        ldx #1                  ; channel to process, start with channel 1
snd_ch     
        lda snd_on,x            ; get sound length counter for this channel
        beq snd_done            ; are we playing a sound? a>1 
        dec snd_on,x            ; yes, decrese the sound length counter for this channel
        bne snd_cont            ; did we reach the end of the sound length?
        lda #0                  ; yes
        sta AUDV0,x             ; turn off the volume for this channel 
snd_done

snd_cont
        dex                     ; do it again for channel 0
        beq snd_ch              
        rts

       


; define sounds, bounce, reset, backward, forward
sndbank_type
        .byte $0C, $02, $06, $06, $0C, $02, $06, $06, $0C, $02, $06, $06
sndbank_vol
        .byte $02, $06, $04, $04, $02, $06, $04, $04, $02, $06, $04, $04
sndbank_pitch
        .byte $1A, $0E, $1F, $09, $12, $07, $1C, $0B, $14, $03, $19, $0D
sndbank_len
        .byte $01, $08, $03, $03, $0C, $02, $06, $06, $0C, $02, $06, $06


colors:
                    .byte $36, $48, $76, $b4, $ea, $4c, $8a, $a4  ; Player 0-7 colors
                    
                
reversedOrderBits
            .word $00, $80, $40, $c0, $20, $a0, $60, $e0
            .word $10, $90, $50, $d0, $30, $b0, $70, $f0
            .word $08, $88, $48, $c8, $28, $a8, $68, $e8
            .word $18, $98, $58, $d8, $38, $b8, $78, $f8
            .word $04, $84, $44, $c4, $24, $a4, $64, $e4
            .word $14, $94, $54, $d4, $34, $b4, $74, $f4
            .word $0c, $8c, $4c, $cc, $2c, $ac, $6c, $ec
            .word $1c, $9c, $5c, $dc, $3c, $bc, $7c, $fc
            .word $02, $82, $42, $c2, $22, $a2, $62, $e2
            .word $12, $92, $52, $d2, $32, $b2, $72, $f2
            .word $0a, $8a, $4a, $ca, $2a, $aa, $6a, $ea
            .word $1a, $9a, $5a, $da, $3a, $ba, $7a, $fa
            .word $06, $86, $46, $c6, $26, $a6, $66, $e6
            .word $16, $96, $56, $d6, $36, $b6, $76, $f6
            .word $0e, $8e, $4e, $ce, $2e, $ae, $6e, $ee
            .word $1e, $9e, $5e, $de, $3e, $be, $7e, $fe
            .word $01, $81, $41, $c1, $21, $a1, $61, $e1
            .word $11, $91, $51, $d1, $31, $b1, $71, $f1
            .word $09, $89, $49, $c9, $29, $a9, $69, $e9
            .word $19, $99, $59, $d9, $39, $b9, $79, $f9
            .word $05, $85, $45, $c5, $25, $a5, $65, $e5
            .word $15, $95, $55, $d5, $35, $b5, $75, $f5
            .word $0d, $8d, $4d, $cd, $2d, $ad, $6d, $ed
            .word $1d, $9d, $5d, $dd, $3d, $bd, $7d, $fd
            .word $03, $83, $43, $c3, $23, $a3, $63, $e3
            .word $13, $93, $53, $d3, $33, $b3, $73, $f3
            .word $0b, $8b, $4b, $cb, $2b, $ab, $6b, $eb
            .word $1b, $9b, $5b, $db, $3b, $bb, $7b, $fb
            .word $07, $87, $47, $c7, $27, $a7, $67, $e7
            .word $17, $97, $57, $d7, $37, $b7, $77, $f7
            .word $0f, $8f, $4f, $cf, $2f, $af, $6f, $ef
            .word $1f, $9f, $5f, $df, $3f, $bf, $7f, $ff    
            
            org 	$FFD0
            .word $0000,$0000
            .word $B3A1, $1077
            .word $0000,$2420
            .word $0000,$0000
            
                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)



                