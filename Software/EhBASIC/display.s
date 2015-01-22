	.include "macro.i"


	.export display_init
	.export display_putchar
	
	.import __SCREEN_START__
	.import __IO_START__
	
	
	.zeropage

src:	.res 2
dst:	.res 2
column:	.res 1
row:	.res 1


SCREEN_WIDTH	= 80
SCREEN_HEIGHT	= 50

screen		= __SCREEN_START__

display_base		= __IO_START__
display_mode		= __IO_START__ + 3
display_irq_mask	= __IO_START__ + 4
display_irq_status	= __IO_START__ + 5

	
	.code

display_init:
	lda #<screen
	sta display_base
	lda #>screen
	sta display_base + 1
	lda #$00
	sta display_base + 2
	lda #0
	sta display_mode
	lda #0
	sta display_irq_mask
	;jmp display_clear

display_clear:
	ldax #screen
	stax dst
	ldx #$10
	ldy #0
	sty column
	sty row
	lda #' '
@clear:
	sta (dst),y
	iny
	bne @clear
	inc dst + 1
	dex
	bne @clear

	ldax #screen
	stax dst
	rts

display_cr:
	lda #0
	sta column
	rts

display_putchar:
	cmp #$0d
	beq display_cr
	cmp #$0a
	beq @lf
	
	ldy column
	sta (dst),y
	iny
	sty column
	cpy #SCREEN_WIDTH
	bne @done
	
	ldy #0
	sty column

@lf:	
	lda row
	cmp #SCREEN_HEIGHT - 1
	
	bcs @scroll
	
	inc row
	
	lda dst
	clc
	adc #SCREEN_WIDTH
	sta dst
	bcc @done
	inc dst + 1
@done:
	rts

@scroll:
	ldax #screen
	stax dst
	ldax #screen + SCREEN_WIDTH
	stax src
	
	ldx #SCREEN_HEIGHT - 1
@copyline:
	ldy #SCREEN_WIDTH - 1
@copychars:
	lda (src),y
	sta (dst),y
	dey
	bpl @copychars
	
	lda src
	sta dst
	clc
	adc #SCREEN_WIDTH
	sta src
	lda src + 1
	sta dst + 1
	adc #0
	sta src + 1
	
	dex
	bne @copyline
	
	ldy #SCREEN_WIDTH - 1
	lda #' '
@clear:
	sta (dst),y
	dey
	bpl @clear
	
	rts
