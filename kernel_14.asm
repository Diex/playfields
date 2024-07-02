                processor 6502		; -----------------------------------------------------
                include	 "vcs.h"	;
                include  "macro.h"	; 
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/KJYeQjJTkj4
                        	        ; Email - 8blit0@gmail.com
     
                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ 192            ; playfield height
SPEED           equ 8                             
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
                lda #PF_H
                sta scanline                
                
                
                sta WSYNC           ; primera linea visible                
                
          
render:		    sta WSYNC           ; no lo cuento en la snl  
                
                lda scanline
                adc c16_1+1
                ror                
                ror
                ror
                ror
                sta COLUPF
          

                jsr kernel1
                sta PF2
                dec scanline                 ; (2)



                sta WSYNC
                
                lda scanline
                ror
                ror
                ror                                             
                sta COLUPF
          
                jsr kernel2
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
                ; ror
                adc temp                
                rts

kernel2:

                lda c16_1+0    
                adc scanline
                rol
                eor temp
                sta temp
                lda c16_1+0
                rol
                eor temp
                
                rts


            ; Shift a 16bit value by one place left (e.g. multiply by two)
asl16       ASL params+0       ;Shift the LSB
            ROL params+1       ;Rotate the MSB
            rts


inc16	        clc		
                lda c16_1+1
                adc #1
                sta c16_1+1
                bcc .+4             
                inc c16_1+0
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

            
            org 	$FFD0
            .word $0000,$0000
            .word $B3A1, $1077
            .word $0000,$2420
            .word $0000,$0000
            
                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)



                