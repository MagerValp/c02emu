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
	sta $00,x		; Map RAM bank x at $x000.
	dex
	bpl @reset_mmu
	lda #$a0		; Map I/O at $e000.
	sta $0e
	lda #$ff		; Map ROM at $f000.
	sta $0f
	
	ldx #0
	txa
@clear_ram:
	stz a:$0010,x
	pha
	inx
	bne @clear_ram
	
	ldax #rom_nmih
	stax vec_nmih
	ldax #rom_irqh
	stax vec_irqh
	
	jsr display_init
	
	ldx #0
@printmsg:
	lda msg_startup,x
	beq :+
	sta $1000,x
	inx
	bne @printmsg
:	
	cli
	
:	wai
	jmp :-
	
	

j_nmih:
	jmp (vec_nmih)
rom_nmih:
	inc $104e
	rti
j_irqh:
	jmp (vec_irqh)
rom_irqh:
	pha
	inc $104f
	lda $e005
	sta $e005
	pla
	rti


	.rodata

msg_startup:
	.asciiz "c02emu"


	.segment "VECTORS"

vec_nmi:	.addr j_nmih
vec_res:	.addr reset
vec_irq:	.addr j_irqh
