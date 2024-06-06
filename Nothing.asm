;	>>> Nothing by JAC! <<<
;
;	Created 2013-11-07 for Sillventure 2013 in Gdansk.
;
;	@com.wudsn.ide.asm.hardware=atari2600

; Type         NTSC  PAL/SECAM
;  V-Sync      3     3    scanlines
;  V-Blank     37    45   scanlines (upper border)
;  Picture     192   228  scanlines
;  Overscan    30    36   scanlines (lower border)
;  Frame Rate  60    50   Hz
;  Frame Time  262   312  scanlines

;	Set to 0 for NTSC version and to 1 for PAL vesion
pal	= 1;

;	Set to 0 for fast animations
text_delay	= 0;
curtain_delay	= 1;
bar_delay	= 1;
sinus2_max	= 171

	icl "../VCS.asm"


; Constant declarations

	
	.if pal = 0
	.print "Using NTSC colors"
	.enum color
	yellow = $10
	red = $40
	violet = $50
	blue_violet = $60
	blue_seven = $70
	blue = $80
	blue_green = $c0
	green = $d0
	olive = $e0
	gold = $f0
	.ende
	.else
	.print "Using PAL colors"
	.enum color
	red = $60
	olive = $40
	yellow = $20
	violet = $a0
	blue_violet = $c0
	blue_seven = $b0
	blue = $d0
	blue_green = $90
	green = $50
	gold = $20
	.ende
	.endif

; Zeropage variable declaration

		org $80	;Zeropage variables
cnt		.ds 1
sound_zp	.ds 3	;3 bytes

plot_cnt_hi	.ds 1	;Plot counter

text_cnt_lo	.ds 2	;Up and down scroll counter
text_cnt_hi	.ds 2	;Text phase counter

volatile_zp	.ds 6

kernel_zp	.ds .len [kernel_zp_rom]
kernel_zp_low	= kernel_zp+kernel_zp_rom.low-kernel_zp_rom
kernel_zp_hi	= kernel_zp_low+1

effect_lines	= $67

sinus_cnt1	.ds 1
sinus_add1	.ds 1
sinus_step1	.ds 1
sinus_cnt2	.ds 1
sinus_add2	.ds 1
sinus_step2	.ds 1

zp_end
	.if zp_end >$fc
		.error "zp_end=",zp_end
	.endif

;===============================================================

	opt h-f+

	org $f000		;Main part

	icl "Nothing-Sound.asm"

;===============================================================

	.proc cart
start	cld
	ldx #0
	txa
;	tay
init
	dex
	txs
	pha
	bne init		;SP=$FF, X = A = 0


	ldx #[.len kernel_zp_rom]-1
copy_kernel_zp
	lda kernel_zp_rom,x
	sta kernel_zp,x
	dex
	bpl copy_kernel_zp

	mva #text_bottom-text_top text_cnt_hi+1	;Start of 2nd line text

;===============================================================

	.proc main
frame_loop
	lsr swchb		;Reset pressed?
	bcc start		;Yes, reset

	jsr vsync_area

	.proc vblank_area
	.if pal = 0 
	lda #45
	.else
	lda #74
	.endif
	sta tim64t

loop	lda intim
	bne loop
	sta wsync
	sta :vblank		;Deactivate VBLANK bit 1
	.endp

;===============================================================

	.proc playfield_area
	ldx #0			;Begin of playfield
	jsr text_box.kernel

	sty pf0
	sty pf1
	sty pf2

	sta wsync		;Top splitt sync 1
	sty colubk		;Top splitter black

	sta wsync		;Top splitt sync 2
	lda #14			;Top splitter white
	sta colubk

	jsr animate.playfield

	sta wsync		;Bottom splitt sync 1
	lda #14			;Bottom splitter white 
	sta colubk
	lda #0
	sta pf0
	sta pf1
	sta pf2
	sta grp0
	sta grp1

	lda #4			;Set flashing bottom text color
	jsr flash
	sta colupf

	sta wsync		;Bottom splitt sync 2
	lda #0			;Bottom splitter black
	sta colubk
	sta ctrlpf		;No reflect

	ldx #1
	jsr text_box.kernel
	sty colubk		;Overscan black
	sty pf0
	sty pf1
	sty pf2
	.endp

;===============================================================

	.proc overscan_area
	lda #2
	sta :vblank		;Activate VBLANK bit 1
	.if pal = 0
	lda #34
	.else
	lda #65
	.endif
	sta tim64t		;Overscan time counter
	
	lda #0			;Set flashing player 0 and 1 colors
	jsr flash
	sta colup0
	lda #8
	jsr flash
	sta colup1
	
	lda #12			;Set flashing top text color
	jsr flash
	sta colupf

	jsr sound.player	;Play sound and returns C=1 if main pattern has changed
	php
	scc
	jsr animate.effect
	plp
	jsr animate.overscan	;Animate all effects

	inc cnt
loop	lda intim
;stop	bmi stop		;Time overrun
	bne loop
	sta wsync
	jmp frame_loop
	
	.endp			;End of overscan

	.endp			;End of main

;===============================================================

	.proc vsync_area
	lda #$0e		;Create 3 lines of vsync=1 plus 1 line of vsync=0
	sta vblank		;Activate VBLANK bit 1 in scanline 308
loop
	sta wsync
	sta vsync
	lsr
	bne loop
	sta vblank		;Deactivate VBLANK bit 1 in scanline 0
	rts
	.endp
	
;===============================================================
	.proc flash
	asl
	adc cnt
	lsr
	and #31
	cmp #16
	bcc *+4
	eor #31
	rts
	.endp

;===============================================================
;	Display text box
;
;	IN : <X> will hold the index of letter pixel we're on couting in lines
;	OUT: <Y> = 0

	.proc text_box

;	Local equates
	text_lines 		= 2
	text_line_height 	= 5
	text_pixel_per_line	= 8
	text_pixel_height	= text_line_height*text_pixel_per_line;
	text_column_offset	= text_lines*text_line_height;

;	Local zero page
	text_temp		= volatile_zp
	text_pixel_counter	= volatile_zp+1
	text_color		= volatile_zp+2

;	IN: <X> = 0/1
	.proc up
	lda text_cnt_lo,x
	cmp #text_pixel_height
	beq no_inc
	.if text_delay <> 0
	lda cnt
	and #text_delay
	bne no_inc
	.endif
	inc text_cnt_lo,x
no_inc	rts
	.endp

;	IN: <X> = 0/1
	.proc down
	lda text_cnt_lo,x
	beq no_dec
	.if text_delay <> 0
	lda cnt
	and #text_delay
	bne no_dec
	.endif
	dec text_cnt_lo,x
	bne no_next
	inc text_cnt_hi,x
no_next
no_dec
	rts
	.endp

	.align $100
	.proc kernel
	sec
	lda #text_pixel_height
	sbc text_cnt_lo,x		;<X>=0/1
	beq no_skip
	tay
skip_loop
	sta wsync
	dey
	bne skip_loop

no_skip	cmp #text_pixel_height
	bcs skip_all			;Full invisible
	adc #<text_background		;C=0
	tay
	mva #text_pixel_per_line text_pixel_counter

	lda text_cnt_hi,x		;<X>=0/1
	tax	
	lda text_colors,x
	sta text_color
	lda text_top,x
	tax

loop	lda text_background_page,y	;Y is index in page
	eor text_color
	sta wsync
	sta colubk	;3 cylces
loop_with_new_line
	lda texts1+text_column_offset*0,x
	sta pf0
	lda texts1+text_column_offset*1,x
	sta pf1
	lda texts1+text_column_offset*2,x
	sta pf2
	bit $00		;3 cycles
	nop
	lda texts1+text_column_offset*3,x
	sta pf0
	lda texts1+text_column_offset*4,x
	sta pf1
	lda texts1+text_column_offset*5,x
	sta pf2
	dec text_pixel_counter
	bne same_line
	mva #text_pixel_per_line text_pixel_counter
	inx
	sta wsync
	iny
	bne loop_with_new_line
	rts

same_line
	iny
	bne loop
skip_all
	sta wsync
	rts
	.endp			;End of kernel
	
	.print "PROC text_box.kernel:", text_box, " - ", text_box+.len text_box-1, " (", .len text_box, " bytes)"
	
	.endp			;End of text_box

;===============================================================
	.proc intro

	.proc kernel

;	Local zero page
	pattern = volatile_zp
	line_cnt = volatile_zp+1
	
	.proc none
	ldx #effect_lines+2
	jmp top
	.endp

	.proc screen
	sta wsync
	lda #0
	sta colubk
	sta wsync
	ldx #effect_lines
	jsr kernel_zp+2
	lda #0
	sta colubk
	rts
	.endp

	.proc top
	lda #0
	cpx #0			;No lines to display
	beq exit
loop	sta wsync
	sta colubk
	sta colupf
	dex
	bne loop
exit	rts
	.endp			;End of top


	.endp			;End of kernel

	.proc overscan
	clc
	lda sinus_cnt1
	adc sinus_add1
	sta sinus_cnt1
	tax
	
	clc
	lda sinus_cnt2
	adc sinus_add2
	cmp #sinus2_max
	scc 
	sbc #sinus2_max
	sta sinus_cnt2
	tay	

	.rept 8
	clc
	lda sinus1,x
	adc sinus2,y
	ror
	sta kernel_zp_low+5*#

	txa
	clc
	adc sinus_step1
	tax
	tya
	clc
	adc sinus_step2
	cmp #sinus2_max
	scc 
	sbc #sinus2_max
	tay
	.endr
	rts
	.endp

	.endp			;End of intro

;===============================================================

	.proc animate

;===============================================================

	.proc nothing
	rts
	.endp

;===============================================================

	.proc playfield		;Animation code to be execute for the  playfield
	jump_ptr = volatile_zp	;Must not be overwritte here

	lda plot_cnt_hi
	asl
	tax
	lda playfield_table,x
	sta jump_ptr
	lda playfield_table+1,x
	sta jump_ptr+1
	jmp (jump_ptr)
	.endp			

;===============================================================

	.proc overscan		;Animation code to be executed during VBLANK
;	Local zero page
	init_flag = volatile_zp
	jump_ptr = volatile_zp+1

	lda #0
	sta init_flag
	bcc same_pattern	;Same pattern

	ldx #.len pattern_table-1
	lda pattern_hi
pattern_loop
	cmp pattern_table,x	;Pattern which increases plot?
	beq next_plot		;Yes
	dex
	bpl pattern_loop
	bmi same_pattern
next_plot
	lda plot_cnt_hi
	cmp #animate.plot.max
	beq same_pattern
	inc plot_cnt_hi
	inc init_flag
same_pattern
	ldx plot_cnt_hi
	txa
	asl
	tax
	lda overscan_table,x
	sta jump_ptr
	lda overscan_table+1,x
	sta jump_ptr+1
	lda init_flag
	jmp (jump_ptr)		;Start with Z=0 in case of INIT
	.endp			;End of overscan


text_box_up_1
	ldx #0
	.byte $2c		;Skip next 2 bytes
text_box_up_2
	ldx #1
	jmp text_box.up

text_box_down_12
	ldx #0
	jsr text_box.down
text_box_down_2
	ldx #1
	jmp text_box.down

;===============================================================

	.local pattern_table

	.byte $02,$04,$08
	.byte $58		;Stop
	.endl

;===============================================================

	.enum plot		;Count value of plot_cnt_hi
	max = 4
	.ende

;===============================================================

	.local playfield_table
	.word intro.kernel.none
	.word intro.kernel.none,intro.kernel.none	;Nothing / JAC!
	.word intro.kernel.screen
	.word stop
	.endl
	
;===============================================================

	.local overscan_table
	.word nothing
	.word text_box_up_1,text_box_up_2			;Nothing / JAC!
	.word intro.overscan
	.word nothing
	.endl

;===============================================================

	.proc effect
	pattern_tmp = volatile_zp

	lda pattern_hi
	and #3
	jne return
	lda pattern_hi
	cmp #8
	bne not_8
	mva #$10 sinus_cnt1
	mva #$00 sinus_cnt2
	rts
not_8	cmp #12
	bne not_12
	mva #1 sinus_add2
	rts
not_12	cmp #16
	bne not_16
	mva #13 sinus_step2
	rts
not_16	cmp #24
	bne not_24
	mva #1 sinus_add1
	mva #31 sinus_step1
	rts
not_24	cmp #32
	bcc not_32
	ldx #0
	cmp #64
	scc
	lda #$ff
	lsr
	lsr
	sta pattern_tmp
	lsr pattern_tmp
	txa
	adc #>mega_colors1
	sta kernel_zp_hi+5*0
	sta kernel_zp_hi+5*4
	lsr pattern_tmp
	txa
	adc #>mega_colors1
	sta kernel_zp_hi+5*2
	sta kernel_zp_hi+5*6
	txa
	lsr pattern_tmp
	adc #>mega_colors1
	sta kernel_zp_hi+5*1
	sta kernel_zp_hi+5*5
	lsr pattern_tmp
	txa
	adc #>mega_colors1
	sta kernel_zp_hi+5*3
	sta kernel_zp_hi+5*7

not_32	lda pattern_hi
	cmp #48
	bne not_48
	asl sinus_step1
	rts

not_48	lda pattern_hi
	cmp #56
	bne not_56
	asl sinus_step2
	rts

not_56	cmp #64
	bne not_64
	inc sinus_add1
	rts
	
not_64	cmp #72
	bne not_72
	inc sinus_add2
	rts

not_72	cmp #80
	bne not_80
	dec sinus_add1
	dec sinus_add2
	asl sinus_step1
	rts

not_80	cmp #84
	bne not_84
	lda #0
	sta sinus_step1
	sta sinus_step2
	rts

not_84

return	rts
	.endp

	.proc stop		;Stop and show blank screen at 50 FPS
	delay_cnt = $80

	lda #0
	tax
clear	sta $00,x
	inx
	bne clear

kernel	jsr vsync_area
	ldx #308/2
loop	sta wsync
	sta wsync
	dex
	bne loop
	lsr swchb		;Reset pressed?
	bcc restart		;Yes, reset
	inw delay_cnt
	lda delay_cnt+1
	cmp #2			;Wait 2*$100/50=10,24s	
	bne kernel
restart	jmp ($fffc)
	.endp			;End of stop

;===============================================================

	.print "LOCAL pattern_table:	", pattern_table, " - ", pattern_table+.len pattern_table-1, " (", .len pattern_table, " bytes)"
	.print "LOCAL overscan_table:	", overscan_table, " - ", overscan_table+.len overscan_table-1, " (", .len overscan_table, " bytes)"
	.print "LOCAL playfield_table:	", playfield_table, " - ", playfield_table+.len playfield_table-1, " (", .len playfield_table, " bytes)"
	
	.endp			;End of animate
	
;===============================================================

	.endp			;End of cart

	.print "PROC cart:	", cart, " - ", cart+.len cart-1, " (", .len cart, " bytes)"
	.print "Remaining:	", $fa00-cart-.len cart , " bytes"


;===============================================================
;	org $f800
texts1	ins "Nothing-Text.bin"

text_top	.byte 0
text_bottom	.byte 5

text_colors	.byte color.blue
		.byte color.red

;===============================================================
	org $f900		;One page player graphics including padding
text_background_page

	org $fa00-40		;40 bytes of text background up to end of page
text_background			;Background colors
	.byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	.byte $0d,$0f,$0d,$0d,$0b,$0d,$0b,$0b
	.byte $09,$0b,$09,$09,$07,$09,$07,$07
	.byte $05,$07,$05,$05,$03,$05,$03,$03
	.byte $00,$00,$00,$00,$00,$00,$00,$00

;===============================================================
	org $fa00		;One page sinus table
sinus1	dta b(sin($2f,$2e,256));Sinus table
sinus2	dta b(sin($3f,$3e,sinus2_max));Sinus table

	org $fc00
	.local mega_colors1
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00

	.byte $00,$02
	.byte $00,$02,$04
	.byte $00,$02,$04,$06
	.byte $00,$02,$04,$06,$08
	.byte $00,$02,$04,$06,$08,$0a
	.byte $00,$02,$04,$06,$08,$0a,$0c
	.byte $00,$02,$04,$06,$08,$0a,$0c,$0e
	.byte $00,$02,$04,$06,$08,$0a,$0c,$0e
	.byte $00,$02,$04,$06,$08,$0a,$0c,$0e
	.byte $02,$04,$06,$08,$0a,$0c,$0e,$0e
	.byte $04,$06,$08,$0a,$0c,$0e,$0e,$0e
	.byte $06,$08,$0a,$0c,$0e,$0e,$0e,$0e
	.byte $0e,$0e,$0e,$0e,$0c,$0a,$08,$06
	.byte $0e,$0e,$0e,$0c,$0a,$08,$06,$04
	.byte $0e,$0e,$0c,$0a,$08,$06,$04,$02
	.byte $0e,$0c,$0a,$08,$06,$04,$02,$00
	.byte $0e,$0c,$0a,$08,$06,$04,$02,$00
	.byte $0e,$0c,$0a,$08,$06,$04,$02,$00
	.byte $0c,$0a,$08,$06,$04,$02,$00
	.byte $0a,$08,$06,$04,$02,$00
	.byte $08,$06,$04,$02,$00
	.byte $06,$04,$02,$00
	.byte $04,$02,$00
	.byte $02,$00

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.endl

	org $fd00
	.local mega_colors2
	c8 = $60
	c7 = $20
	c6 = $30
	c5 = $50
	c4 = $70
	c3 = $b0
	c2 = $c0
	c1 = $80
	
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00

	.byte c1+$00,c1+$02
	.byte c2+$00,c2+$02,c2+$04
	.byte c3+$00,c3+$02,c3+$04,c3+$06
	.byte c4+$00,c4+$02,c4+$04,c4+$06,c4+$08
	.byte c5+$00,c5+$02,c5+$04,c5+$06,c5+$08,c5+$0a
	.byte c6+$00,c6+$02,c6+$04,c6+$06,c6+$08,c6+$0a,c6+$0c
	.byte c7+$00,c7+$02,c7+$04,c7+$06,c7+$08,c7+$0a,c7+$0c,c7+$0e
	.byte c8+$00,c8+$02,c8+$04,c8+$06,c8+$08,c8+$0a,c8+$0c,c8+$0e
	.byte c1+$00,c1+$02,c1+$04,c1+$06,c1+$08,c1+$0a,c1+$0c,c1+$0e
	.byte c2+$02,c2+$04,c2+$06,c2+$08,c2+$0a,c2+$0c,c2+$0e,c2+$0e
	.byte c3+$04,c3+$06,c3+$08,c3+$0a,c3+$0c,c3+$0e,c3+$0e,c3+$0e
	.byte $06,$08,$0a,$0c,$0e,$0e,$0e,$0e
	.byte $0e,$0e,$0e,$0e,$0c,$0a,$08,$06
	.byte c6+$0e,c6+$0e,c6+$0e,c6+$0c,c6+$0a,c6+$08,c6+$06,c6+$04
	.byte c7+$0e,c7+$0e,c7+$0c,c7+$0a,c7+$08,c7+$06,c7+$04,c7+$02
	.byte c8+$0e,c8+$0c,c8+$0a,c8+$08,c8+$06,c8+$04,c8+$02,c8+$00
	.byte c1+$0e,c1+$0c,c1+$0a,c1+$08,c1+$06,c1+$04,c1+$02,c1+$00
	.byte c2+$0e,c2+$0c,c2+$0a,c2+$08,c2+$06,c2+$04,c2+$02,c2+$00
	.byte c3+$0c,c3+$0a,c3+$08,c3+$06,c3+$04,c3+$02,c3+$00
	.byte c4+$0a,c4+$08,c4+$06,c4+$04,c4+$02,c4+$00
	.byte c5+$08,c5+$06,c5+$04,c5+$02,c5+$00
	.byte c6+$06,c6+$04,c6+$02,c6+$00
	.byte c7+$04,c7+$02,c7+$00
	.byte c8+$02,c8+$00

	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.endl

;===============================================================
	org $ff00		;One page of pattern data

	.proc kernel_zp_rom
loop	bit $00
	nop
	nop
	nop

low	= *+1
	lda mega_colors1,x	;0
	sta colubk
	lda mega_colors1,x	;1
	sta colubk
	lda mega_colors1,x	;2
	sta colubk
	lda mega_colors1,x	;3
	sta colubk
	lda mega_colors1,x	;4
	sta colubk
	lda mega_colors1,x	;5
	sta colubk
	lda mega_colors1,x	;6
	sta colubk
	lda mega_colors1,x	;7
	sta colubk
	sty wsync
	dex
	bne loop
	rts
	.endp

;===============================================================

	org $ff80
	.byte 'Nothing - by JAC! 2013-11-07 03:15:00',0

	org $fffc		;Cartridge vectors
	.word cart.start	;Reset vector
	.word cart.start	;IRQ vector, not really required
