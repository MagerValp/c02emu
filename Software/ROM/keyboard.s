	.include "macro.i"
	.include "io.i"


	.export keyboard_init
	.export keyboard_scan
	
	.import __IO_START__
	

	.bss

counter:	.res 1


	.code

keyboard_init:
	lda #0
	sta counter
	rts

keyboard_scan:
	lda keyboard_queue_size
	beq @done

	lda keyboard_queue
	ldy counter
	sta $1050,y
	inc counter
	jmp keyboard_scan
@done:
	rts
