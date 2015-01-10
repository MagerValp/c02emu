	.include "macro.i"
	
	
	.export display_init
	
	
	.code

display_init:
	lda #0
	sta $e300
	rts
