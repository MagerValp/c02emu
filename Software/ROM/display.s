	.include "macro.i"
	
	
	.export display_init
	
	
	.code

display_init:
	lda #$00
	sta $e000
	lda #$10
	sta $e001
	lda #$00
	sta $e002
	lda #0
	sta $e003
	lda #1
	sta $e004
	rts
