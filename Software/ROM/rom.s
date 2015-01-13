	.include "macro.i"


	.import display_init
	

	.bss

vec_nmih:	.res 2
vec_irqh:	.res 2


	.code

reset:
	sei
	cld
	ldx #$ff
	txs
	
	ldx #$0d
@reset_mmu:
	txa
	sta $f000,x
	dex
	bpl @reset_mmu
	lda #$fe
	sta $f00e
	lda #$ff
	sta $f00f
	
	ldx #0
	txa
@clear_ram:
	sta $00,x
	sta $0100,x
	inx
	bne @clear_ram
	
	ldax #rom_nmih
	stax vec_nmih
	ldax #rom_irqh
	stax vec_irqh
	
	jsr display_init
	
	ldx #0
	stx $e300
@printmsg:
	lda msg_startup,x
	beq :+
	sta $e200,x
	inx
	bne @printmsg
:	
	cli
	jmp *
	
	

j_nmih:
	jmp (vec_nmih)
rom_nmih:
	inc $e24e
	rti
j_irqh:
	jmp (vec_irqh)
rom_irqh:
	inc $e24f
	rti


	.rodata

msg_startup:
	.asciiz "c02emu"


	.segment "VECTORS"

vec_nmi:	.addr j_nmih
vec_res:	.addr reset
vec_irq:	.addr j_irqh
