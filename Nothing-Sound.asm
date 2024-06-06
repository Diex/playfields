;
;	>>> Nothing  by JAC! <<<
;
;	Created 2013-11-07 for Sillventure 2013 in Gdansk.
;
;	This is the sound include based on SONGMAIN.BIN by Qotile/Paul Slocum.
;
;	@com.wudsn.ide.asm.hardware=atari2600
;	@com.wudsn.ide.asm.mainsourcefile=Nothing.asm

pattern_delay	= sound_zp		;0..2
pattern_lo	= sound_zp+1		;0..31
pattern_hi	= sound_zp+2		;0..14, total length = 3*32*15 = 1440 frames = 24s

voice_number	= volatile_zp		;volatile
pattern_ptr	= volatile_zp+1		;volatile
temp		= volatile_zp+3		;volatile
	.proc sound

;===============================================================
;	Player to be called every frame
;	OUT: C=1 is high pattern has changed now, C=0 otherwise

	.proc player			;Play two voices
	ldy pattern_hi
	
	ldx tune.track1,y
	bpl not_last_pattern
	ldy #0
	sty pattern_hi
	ldx tune.track1,y
not_last_pattern
	lda #0
	jsr play_voice
	ldy pattern_hi
	ldx tune.track2,y
	lda #1
	jsr play_voice

	ldy #0				;Increament delay, lo and hi counters
	lda pattern_delay
	clc

	.if pal = 0
	adc #86
	.else
	adc #103
	.endif
	sta pattern_delay
	bcc same_pattern_lo
	ldx pattern_lo
	inx
	stx pattern_lo

	cpx #32
	bne same_pattern_hi
	inc pattern_hi
	sty pattern_lo
	sec				;Return with C=1 if high pattern has changed now
	rts

same_pattern_lo
same_pattern_hi
	clc				;Return with C=0 if high pattern has changed now
	rts

;===============================================================
;	Play one voice
;	IN: <A>=voice #0 or #1
;	IN: <X>=pattern_hi
	.proc play_voice
	sta voice_number
	lda tune.pattern_adr,x
	sta pattern_ptr
	inx
	lda tune.pattern_adr,x
	sta pattern_ptr+1
	ldy pattern_lo
	lda (pattern_ptr),y
	beq silence

;	Get frequency and distortion from packed pattern byte
;	IN:  <A> = pattern byte, %DDDFFFFF with %DDD = 3 bit distortion control index, %FFFFF = 5 bit frequency or $ff
;	OUT: <A> = audf0/1 value
;	OUT: <X> = audc/1 value
	.proc get_audfc
	cmp #$ff
	beq exit_ff
	tax
	and #$1F
;	pha
	sta temp
	txa
	lsr
	lsr
	lsr
	lsr
	lsr
	tax
	lda control,x
	tax
;	pla
	lda temp
	.byte $2c	;Skip next 2 bytes
exit_ff	lda #$ff
	.endp		;End of get_audfc

	ldy voice_number
	sta audf0,y
	stx audc0,y
	cmp #$ff
	beq exit_ff

	.proc get_audv
	lda pattern_lo
	and #$18
	lsr
	lsr
	lsr
	ora #$20
	tay
	lda pattern_lo
	and #7
	tax
	lda (pattern_ptr),y
	and bitmask,x
	beq bit_zero
	lda #$0F
	.byte $2c	;Skip next 2 bytes
bit_zero
	lda #$06
	.endp		;End of get_audv

silence	ldy voice_number
	sta audv0,y
exit_ff	rts


control	.byte $04,$06,$07,$08,$0F,$0C,$01,$03	;Used by get_audfc
bitmask	.byte $80,$40,$20,$10,$08,$04,$02,$01	;User by get_audv

	.endp
	.endp

	.proc tune

track1	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $0a,$0a,$0c,$0c,$0a,$0a,$0c,$0c
	.byte $0e,$0e,$10,$10,$2a,$2a,$10,$10
	.byte $0e,$0e,$10,$10,$2a,$2a,$10,$10
	.byte $12,$12,$14,$14,$12,$12,$14,$14
	.byte $1e,$1e,$20,$20,$2c,$2c,$20,$20
	.byte $1e,$1e,$20,$20,$2c,$2c,$20,$20
	.byte $26,$26,$28,$28,$26,$26,$28,$28
	.byte $26,$26,$28,$28,$26,$26,$28,$28
;	.byte $22,$22,$24,$24,$22,$22,$24,$24
;	.byte $22,$22,$24,$24,$22,$22,$24,$24
;	.byte $22,$22,$24,$24,$22,$22,$24,$24
;	.byte $22,$22,$24,$24,$22,$22,$24,$24
	.byte $1a,$1a,$1c,$1c,$02,$02,$04,$04
	.byte $06,$06,$08,$08,$16,$16,$18,$18
	.byte $ff

track2	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $16,$16,$18,$18,$1a,$1a,$1c,$1c
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $16,$16,$18,$18,$1a,$1a,$1c,$1c
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $16,$16,$18,$18,$1a,$1a,$1c,$1c
;	.byte $02,$02,$04,$04,$06,$06,$08,$08
;	.byte $16,$16,$18,$18,$1a,$1a,$1c,$1c
;	.byte $02,$02,$04,$04,$06,$06,$08,$08
;	.byte $16,$16,$18,$18,$1a,$1a,$1c,$1c
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $02,$02,$04,$04,$06,$06,$08,$08
	.byte $ff


pattern_adr
	.word lf8de,lf8ba,lf896,lf872
	.word lf84e,lf82a,lf806,lf7e2
	.word lf79a,lf70a,lf6e6,lf67a
	.word lf656,lf632,lf5c6,lf7be
	.word lf72e,lf6c2,lf69e,lf5ea
	.word lf60e,lf776,lf752,lf752

lf5c6	.byte $af,$b7,$bd,$b7,$af,$b7,$bd,$b7
	.byte $b3,$b7,$bd,$b7,$b3,$b7,$bd,$b7
	.byte $b3,$b7,$bd,$b7,$b3,$b7,$bd,$b7
	.byte $b3,$b7,$bd,$b7,$b3,$b7,$bd,$b7
	.byte $00,$00,$00,$00
lf5ea	.byte $11,$00,$11,$00
	.byte $61,$17,$17,$00,$68,$68,$68,$68
	.byte $61,$09,$09,$00,$61,$09,$09,$00
	.byte $7e,$0b,$0b,$00,$68,$00,$00,$00
	.byte $61,$11,$11,$00,$a0,$80,$a0,$80
lf60e	.byte $7e,$0e,$0e,$00,$61,$1a,$1a,$00
	.byte $68,$68,$68,$68,$61,$00,$09,$00
	.byte $61,$00,$09,$00,$17,$00,$0f,$00
	.byte $68,$00,$68,$00,$61,$00,$0f,$00
	.byte $a0,$80,$a0,$a0
lf632	.byte $a4,$af,$ba,$af
	.byte $a4,$af,$ba,$af,$a4,$af,$ba,$af
	.byte $a4,$af,$ba,$af,$a4,$af,$ba,$af
	.byte $a4,$af,$ba,$af,$a4,$af,$ba,$af
	.byte $a4,$af,$ba,$af,$00,$00,$00,$00
lf656	.byte $ab,$b1,$bd,$b1,$ab,$b1,$bd,$b1
	.byte $ab,$b1,$bd,$b1,$ab,$b1,$bd,$b1
	.byte $ab,$b1,$bd,$b1,$ab,$b1,$bd,$b1
	.byte $ab,$b1,$bd,$b1,$ab,$b1,$bd,$b1
	.byte $00,$00,$00,$00
lf67a	.byte $a4,$b3,$b7,$b3
	.byte $a4,$b3,$b7,$b3,$a4,$b3,$b7,$b3
	.byte $a4,$b3,$b7,$b3,$a4,$b3,$b7,$b3
	.byte $a4,$b3,$b7,$b3,$a4,$b3,$b7,$b3
	.byte $a4,$b3,$b7,$b3,$00,$00,$00,$00
lf69e	.byte $7e,$00,$61,$00,$61,$00,$61,$00
	.byte $68,$68,$68,$68,$61,$00,$61,$00
	.byte $61,$00,$61,$00,$61,$00,$61,$00
	.byte $68,$00,$68,$00,$61,$00,$61,$00
	.byte $80,$80,$80,$80
lf6c2	.byte $61,$00,$61,$00
	.byte $61,$00,$61,$00,$68,$68,$68,$68
	.byte $61,$00,$61,$00,$61,$00,$61,$00
	.byte $7e,$00,$61,$00,$68,$00,$61,$00
	.byte $61,$00,$61,$00,$80,$80,$80,$80
lf6e6	.byte $7e,$00,$00,$00,$61,$00,$00,$00
	.byte $68,$68,$68,$68,$61,$00,$00,$00
	.byte $61,$00,$00,$00,$61,$00,$00,$00
	.byte $68,$00,$68,$00,$61,$00,$00,$00
	.byte $a0,$80,$a0,$a0
lf70a	.byte $61,$00,$00,$00
	.byte $61,$00,$00,$00,$68,$68,$68,$68
	.byte $61,$00,$00,$00,$61,$00,$00,$00
	.byte $7e,$00,$00,$00,$68,$00,$00,$00
	.byte $61,$00,$00,$00,$a0,$80,$a0,$80
lf72e	.byte $7e,$13,$13,$00,$61,$1a,$1a,$00
	.byte $68,$68,$68,$68,$61,$00,$00,$00
	.byte $61,$00,$11,$00,$17,$00,$11,$00
	.byte $68,$00,$68,$00,$61,$00,$13,$00
	.byte $a0,$80,$a0,$a0
lf752	.byte $1d,$00,$1d,$00
	.byte $61,$1a,$1a,$00,$68,$68,$68,$68
	.byte $61,$11,$11,$00,$61,$ab,$ab,$00
	.byte $7e,$17,$17,$00,$68,$00,$00,$00
	.byte $61,$1d,$1d,$00,$a0,$80,$a0,$80
lf776	.byte $1d,$00,$1d,$00,$1a,$1a,$00,$00
	.byte $68,$68,$68,$68,$11,$11,$00,$00
	.byte $ab,$00,$ab,$00,$7e,$17,$00,$00
	.byte $68,$00,$00,$00,$1d,$1d,$00,$00
	.byte $a0,$80,$08,$80
lf79a	.byte $7e,$00,$13,$00
	.byte $1a,$1a,$00,$00,$68,$68,$68,$68
	.byte $11,$11,$00,$00,$11,$00,$11,$00
	.byte $17,$17,$13,$00,$68,$00,$68,$00
	.byte $13,$13,$00,$00,$a0,$80,$a0,$a0
lf7be	.byte $1d,$00,$1d,$00,$61,$1a,$1a,$00
	.byte $68,$68,$68,$68,$61,$0e,$0e,$00
	.byte $61,$0e,$0e,$00,$7e,$11,$11,$00
	.byte $68,$00,$00,$00,$61,$1d,$1d,$00
	.byte $a0,$80,$a0,$80
lf7e2	.byte $1d,$00,$1d,$00
	.byte $1a,$1a,$00,$00,$68,$68,$68,$68
	.byte $0e,$0e,$00,$00,$0e,$00,$0e,$00
	.byte $7e,$11,$00,$00,$68,$00,$00,$00
	.byte $1d,$1d,$00,$00,$a0,$80,$a8,$80
lf806	.byte $13,$00,$13,$00,$1a,$1a,$00,$00
	.byte $00,$00,$00,$00,$11,$11,$00,$00
	.byte $11,$00,$11,$00,$17,$17,$00,$00
	.byte $00,$00,$00,$00,$13,$13,$00,$00
	.byte $a0,$00,$a0,$00
lf82a	.byte $1d,$00,$1d,$00
	.byte $1a,$1a,$00,$00,$00,$00,$00,$00
	.byte $0e,$0e,$00,$00,$0e,$00,$0e,$00
	.byte $11,$11,$00,$00,$00,$00,$00,$00
	.byte $1d,$1d,$00,$00,$a0,$00,$a0,$00
lf84e	.byte $af,$b3,$ba,$b3,$af,$b3,$ba,$b3
	.byte $af,$b3,$ba,$b3,$af,$b3,$ba,$b3
	.byte $af,$b3,$ba,$b3,$af,$b3,$ba,$b3
	.byte $af,$b3,$ba,$b3,$af,$b3,$ba,$b3
	.byte $00,$00,$00,$00
lf872	.byte $b1,$b7,$bd,$b7
	.byte $b1,$b7,$bd,$b7,$b1,$b7,$bd,$b7
	.byte $b1,$b7,$bd,$b7,$b1,$b7,$bd,$b7
	.byte $b1,$b7,$bd,$b7,$b1,$b7,$bd,$b7
	.byte $b1,$b7,$bd,$b7,$00,$00,$00,$00
lf896	.byte $a9,$af,$ba,$af,$a9,$af,$ba,$af
	.byte $a9,$af,$ba,$af,$a9,$af,$ba,$af
	.byte $a9,$af,$ba,$af,$a9,$af,$ba,$af
	.byte $a9,$af,$ba,$af,$a9,$af,$ba,$af
	.byte $00,$00,$00,$00
lf8ba	.byte $ae,$b1,$b7,$b1
	.byte $ae,$b1,$b7,$b1,$ae,$b1,$b7,$b1
	.byte $ae,$b1,$b7,$b1,$ae,$b1,$b7,$b1
	.byte $ae,$b1,$b7,$b1,$ae,$b1,$b7,$b1
	.byte $ae,$b1,$b7,$b1,$00,$00,$00,$00
lf8de	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.endp

	.print "PROC tune:", tune, " - ", tune+.len tune-1, " (", .len tune, " bytes)"	

	.endp
	
	.print "PROC sound:", sound, " - ", sound+.len sound-1, " (", .len sound, " bytes)"
