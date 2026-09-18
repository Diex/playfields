                processor 6502
                include "vcs.h"
                include "macro.h"

; Minimal Atari 2600 boilerplate - displays a blank black screen
; Email - 8blit0@gmail.com

PF_H            equ 192             ; playfield height (visible scanlines)

; ============================================================================
; Variables
; ============================================================================
                seg.u   vars
                org     $80

temp            ds 1                ; general purpose temporary variable

; ============================================================================
; Main Program
; ============================================================================
                seg     main
                org     $F000

reset:
                CLEAN_START         ; clear all RAM, TIA registers, set stack

; ============================================================================
; Main Frame Loop
; ============================================================================
nextframe:
                VERTICAL_SYNC       ; 3 scanlines vertical sync

; -------- Vertical Blank (37 scanlines) ------------------------------------
                lda #44             ; 37 scanlines * 76 cycles = 2812 / 64 = ~44
                sta TIM64T          ; start timer

                ; Game logic goes here during vblank
                ; (currently nothing to do)

                ; Wait for timer to complete
waitvblank:
                lda INTIM
                bne waitvblank

                sta WSYNC           ; finish last scanline

; -------- Visible Display (192 scanlines) ----------------------------------
                lda #0
                sta VBLANK          ; turn on video output

                ; Set screen to black with white playfield
                                sta COLUBK          ; background color = black ($00)
                                lda #$0E
                                sta COLUPF          ; playfield color = white

                                ; Set playfield registers for a horizontal line
                                lda #$FF
                                sta PF0             ; left section
                                sta PF1             ; middle section  
                                sta PF2             ; right section

                                ldy #PF_H           ; 192 scanlines to draw
                
kernel:
                                sta WSYNC           ; wait for horizontal sync
                
                                ; Draw white line on first scanline, then clear
                                cpy #PF_H
                                bne clear_line
                                lda #$FF
                                sta PF0
                                sta PF1
                                sta PF2
                                jmp continue
                
clear_line:
                                lda #$00
                                sta PF0
                                sta PF1
                                sta PF2
                
continue:
                                dey
                                bne kernel

                ; -------- Overscan (30 scanlines) ------------------------------------------
                                lda #2
                                sta VBLANK          ; turn off video output
                lda #35             ; 30 scanlines * 76 cycles = 2280 / 64 = ~35
                sta TIM64T          ; start timer

                ; Post-frame logic goes here
                ; (currently nothing to do)

                ; Wait for timer to complete
waitoverscan:
                lda INTIM
                bne waitoverscan

                jmp nextframe       ; repeat forever

; ============================================================================
; Interrupt Vectors
; ============================================================================
                org $FFFA

                .word reset         ; NMI
                .word reset         ; RESET
                .word reset         ; IRQ
