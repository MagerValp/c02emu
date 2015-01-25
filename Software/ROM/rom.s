	.include "macro.i"
	.include "io.i"

	
	.import display_init
	.import display_putchar
	
	.import keyboard_init
	.import keyboard_get_event
	.import keyboard_scan
	
	.import keymap_translate


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
	sta mmu,x		; Map RAM bank x at $x000.
	dex
	bpl @reset_mmu
	lda #$a0		; Map I/O at $e000.
	sta mmu+$0e
	lda #$ff		; Map ROM at $f000.
	sta mmu+$0f
	
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
	jsr keyboard_init
	
	ldx #0
@printmsg:
	lda msg_startup,x
	beq :+
	jsr display_putchar
	inx
	bne @printmsg
:	
	cli

loop:	
	wai
	
	jsr keyboard_get_event
	cmp #0
	beq loop
	
	bit #$80
	beq loop
	
	jsr keymap_translate
	beq loop
	
	jsr display_putchar
	bra loop
	
	

j_nmih:
	jmp (vec_nmih)
rom_nmih:
	inc $104e
	rti
j_irqh:
	jmp (vec_irqh)
rom_irqh:
	pha
	phx
	phy
	inc $104f
	lda $e005
	sta $e005
	jsr keyboard_scan
	ply
	plx
	pla
	rti


	.rodata

msg_startup:
	.byte "c02emu", 10, 0


	.segment "VECTORS"

vec_nmi:	.addr j_nmih
vec_res:	.addr reset
vec_irq:	.addr j_irqh
