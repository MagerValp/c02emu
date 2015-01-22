pass:
	lda #0
	.byte $db
fail:
	lda #$ff
	.byte $db



rom_nmih:
rom_irqh:
	rti


	.rodata

msg_startup:
	.asciiz "c02emu"


	.segment "VECTORS"

vec_nmi:	.addr rom_nmih
vec_res:	.addr reset
vec_irq:	.addr rom_irqh
