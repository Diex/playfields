                processor 6502		; -----------------------------------------------------
                include	 "vcs.h"	;
                include  "macro.h"	; 
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/KJYeQjJTkj4
                        	        ; Email - 8blit0@gmail.com
     
                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ 192            ; playfield height
SPEED           equ 1                             
                seg.u	temp		; uninitialized segment
                org	$80             ; origin set at base of ram

                                    ; up to 9F
c16_1           ds 2
; c24_1           ds 3

params          ds 8
plfys           ds 3
revbits         ds 2
ghostColPtr     ds 2                ; Pointer to which color palette to use
snd_on          ds 2            ; 1 byte per audio channel - greater than 0 if sound is playing

                seg.u	vars		
                org	$A0             

temp            ds 4                
scanline        ds 1                ; 1 byte - current scanline
fcount          ds 1                ; 1 byte - frame counter
t_              ds 2                ; 1 byte - temp
mod_1           ds 1                ; 1 byte - modulo 1

                
                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                lda #1
                sta CTRLPF

                lda #$1E
                sta COLUPF          

                lda #$02
                sta c16_1+0

                lda SPEED
                sta mod_1

nextframe:		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines
; -------- set timer -------------------------------
                                    ; 37 scanlines x 76 machine cycles per scanline = 2812 machine cycles
                                    ; 2812 machine cycles / 64 clocks = 43.9375
                lda #44             ; We'll round down, and clean up the remaining cycles with a WSYNC
                sta TIM64T          ; Set a count of 43 with 64-clock interval
; -------- do stuff  -------------------------------

                dec mod_1
                bne .+10
                lda SPEED
                sta mod_1
                jsr inc16                

                  ; process the sound channels to turn off volume when counter runs out
                jsr snd_process

; resetColor:     lda c16_1+0
;                 cmp #$0F
;                 bne cont1
;                 lda #$02
;                 sta c16_1+0
; cont1                

                
                
                
; -------- wait ------------------------------------                                
                lda INTIM           ; check the timer          
                bne .-3             ; 2 bytes del opcode (bne) + 1 byte operando                                    
; -------- done ------------------------------------
                lda #0                
                sta VBLANK                
                
                ldx #PF_H
                stx scanline                
                
                
                sta WSYNC           ; primera linea visible                
                
          
render:		    sta WSYNC           ; no lo cuento en la snl  
                

          

                jsr kernel2
                sta PF1         
                dec scanline                 ; (2)




                sta WSYNC

                jsr kernel1
                jsr reverseBits 
                
                sta PF2

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

                ; Read button input
                ldy #1               ; color index set to default yellow
                bit INPT4            ; check D7 of INPT4
                bmi button_nopress   ; branch if minus. D7 will me 0 is button is pressed
                ldy #2
                ldx #0                  ; channel 0
                ldy #0                  ; sound parameter index from sndbank_*
                jsr snd_play            ; call the subroutine to load the audio registers

button_nopress: 
                lda (ghostColPtr),y
                sta COLUBK          ; set the P0 color                
           
switch_color:                
                lda ghost_pColLSB
                sta ghostColPtr     ; (3)
                lda ghost_pColMSB
                sta ghostColPtr+1   ; (3)

                jmp nextframe       ; (3) jump back up to start the next frame

                ; --- END OF FRAME -------


kernel1:
                
                lda c16_1+1
 
                sta temp
                
                           
                rts

kernel2:

                lda c16_1+0    
                
                sta temp
            
                
                rts


            ; Shift a 16bit value by one place left (e.g. multiply by two)
asl16       ASL params+0       ;Shift the LSB
            ROL params+1       ;Rotate the MSB
            rts

ror16       lsr
            bcc *+2   ; or *+3 for 16-bit mode
            ora #$80  ; or #$8000 for 16-bit mode            
            rts

rol16       cmp #$80
            rol
            rts


inc16	        clc		
                lda c16_1+1
                adc #1
                sta c16_1+1
                bcc .+4             
                inc c16_1+0
                rts

reverseBits:
                tax
                lda reversedOrderBits,x      ; Load the value to be reversed from memory
                rts        

; cues a sound to play. sets audio registers based on table lookup sndbank.
; parameters: x = channel (0|1), y = sound to play
snd_play:
        lda sndbank_type,y
        sta AUDC0,x             ; audio control   
        lda sndbank_vol,y
        sta AUDV0,x             ; audio volume
        lda sndbank_pitch,y
        sta AUDF0,x             ; audio frequence
        lda sndbank_len,y
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
        .byte $0C, $02, $06, $06
sndbank_vol
        .byte $02, $06, $04, $04
sndbank_pitch
        .byte $0D, $03, $09, $03
sndbank_len
        .byte $01, $08, $03, $03
    

colors:
                    .byte $36, $48, $76, $b4, $ea, $4c, $8a, $a4  ; Player 0-7 colors



ghost_color:    .byte #$1E          ; Bright Yellow
                .byte #$42          ; Dark Red
                .byte #$98          ; Mid Blue
                .byte #$AE          ; Bright Blue         

ghost_pColLSB:  .byte <ghost_color  ; LSB
ghost_pColMSB:  .byte >ghost_color  ; MSB

              
reversedOrderBits:
                .byte $00, $80, $40, $C0, $20, $A0, $60, $E0
                .byte $10, $90, $50, $D0, $30, $B0, $70, $F0
                .byte $08, $88, $48, $C8, $28, $A8, $68, $E8
                .byte $18, $98, $58, $D8, $38, $B8, $78, $F8
                .byte $04, $84, $44, $C4, $24, $A4, $64, $E4
                .byte $14, $94, $54, $D4, $34, $B4, $74, $F4
                .byte $0C, $8C, $4C, $CC, $2C, $AC, $6C, $EC
                .byte $1C, $9C, $5C, $DC, $3C, $BC, $7C, $FC
                .byte $02, $82, $42, $C2, $22, $A2, $62, $E2
                .byte $12, $92, $52, $D2, $32, $B2, $72, $F2
                .byte $0A, $8A, $4A, $CA, $2A, $AA, $6A, $EA
                .byte $1A, $9A, $5A, $DA, $3A, $BA, $7A, $FA
                .byte $06, $86, $46, $C6, $26, $A6, $66, $E6
                .byte $16, $96, $56, $D6, $36, $B6, $76, $F6
                .byte $0E, $8E, $4E, $CE, $2E, $AE, $6E, $EE
                .byte $1E, $9E, $5E, $DE, $3E, $BE, $7E, $FE
                .byte $01, $81, $41, $C1, $21, $A1, $61, $E1
                .byte $11, $91, $51, $D1, $31, $B1, $71, $F1
                .byte $09, $89, $49, $C9, $29, $A9, $69, $E9
                .byte $19, $99, $59, $D9, $39, $B9, $79, $F9
                .byte $05, $85, $45, $C5, $25, $A5, $65, $E5
                .byte $15, $95, $55, $D5, $35, $B5, $75, $F5
                .byte $0D, $8D, $4D, $CD, $2D, $AD, $6D, $ED
                .byte $1D, $9D, $5D, $DD, $3D, $BD, $7D, $FD
                .byte $03, $83, $43, $C3, $23, $A3, $63, $E3
                .byte $13, $93, $53, $D3, $33, $B3, $73, $F3
                .byte $0B, $8B, $4B, $CB, $2B, $AB, $6B, $EB
                .byte $1B, $9B, $5B, $DB, $3B, $BB, $7B, $FB
                .byte $07, $87, $47, $C7, $27, $A7, $67, $E7
                .byte $17, $97, $57, $D7, $37, $B7, $77, $F7
                .byte $0F, $8F, $4F, $CF, $2F, $AF, $6F, $EF
                .byte $1F, $9F, $5F, $DF, $3F, $BF, $7F, $FF

            
            org 	$FFD0
            .word $0000,$0000
            .word $B3A1, $1077
            .word $0000,$2420
            .word $0000,$0000
            
                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)



                