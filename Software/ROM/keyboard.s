	.include "macro.i"
	.include "io.i"
	.include "keyboard.i"
	

	.export keyboard_init
	.export keyboard_get_event
	.export keyboard_scan
	.export keyboard_mod_state
	
	
	.import __IO_START__
	

	.bss

keyboard_mod_state:	.res 1	; Current modifier state.

break:			.res 1
ext_e0:			.res 1
ext_e1:			.res 1

SQ_LENGTH		= 16
	.align SQ_LENGTH
; The key queue contains scan codes.
scancode_key_queue:	.res SQ_LENGTH
; The mod queue contains modifier state and the MSB indicates if it's a key
; down (0) or key up (1) event.
scancode_mod_queue:	.res SQ_LENGTH
scancode_queue_index:	.res 1
scancode_queue_size:	.res 1


	.code

keyboard_init:
	lda #0
	sta scancode_queue_index
	sta scancode_queue_size
	;jmp keyboard_clear

keyboard_clear:
	lda #0
	sta break
	sta ext_e0
	sta ext_e1
	sta keyboard_mod_state
	rts


; Call from IRQ to read codes from the PS/2 fifo, update modifier state, and
; generate scancode up/down events.
keyboard_scan:
@next:
	lda keyboard_queue_size
	bne :+
	rts
:
	ldx keyboard_queue
	beq @clear
	cpx #$ff
	beq @clear
	
	cpx #$e0
	bne :+
	inc ext_e0
	bra @next
:	
	cpx #$e1
	bne :+
	inc ext_e1
	bra @next
:	
	cpx #$f0
	bne :+
	inc break
	bra @next
:
	cpx #$83		; Remap F7 below $80.
	bne :+
	ldx #KS_F7
:
	cpx #$80		; Ignore all other commands:
	bcs @clear		; AA, EE, FA, FC, FD, FE

	lda ext_e1
	bne @pause
	
	lda ext_e0		; E0 extended codes set the MSB.
	beq :+
	txa
	ora #$80
	tax
:
	cpx #$12
	beq @mod_shift
	cpx #$59
	beq @mod_shift
	
	cpx #$14
	beq @mod_ctrl
	
	cpx #$11
	beq @mod_alt
	
	cpx #$9f
	beq @mod_cmd
	cpx #$a7
	beq @mod_cmd
	
	cpx #$58
	beq @mod_caps
	
	bra @make_break_key

@clear:
	jsr keyboard_clear
	jmp @next

; Skip $14 and $77 codes until we find a $77 with the break flag set.
@pause:
	cpx #$14
	beq @next

	cpx #$77
	bne @clear
	
	lda scancode_queue_size
	cmp #SQ_LENGTH
	bcs @queue_full

	lda #KE_KeyDown
	ldy break
	beq :+
	lda #KE_KeyUp
:
	ldx #KS_Pause
	bra @insert_into_queue

@mod_shift:
	lda #KM_Shift
	bra @mod
@mod_ctrl:
	lda #KM_Ctrl
	bra @mod
@mod_alt:
	lda #KM_Alt
	bra @mod
@mod_cmd:
	lda #KM_Cmd
	bra @mod
@mod_caps:
	lda #KM_Caps
@mod:
	ldy break
	bne @clearmod
;@setmod:
	ora keyboard_mod_state
	sta keyboard_mod_state
	bra @make_break_key
@clearmod:
	eor #$ff
	and keyboard_mod_state
	sta keyboard_mod_state
	;bra @make_break_key

@make_break_key:
	lda scancode_queue_size
	cmp #SQ_LENGTH
	bcs @queue_full
	
	lda keyboard_mod_state
	ldy break
	beq :+
	ora #KE_KeyUp
:
	
@insert_into_queue:
	pha
	lda scancode_queue_index
	clc
	adc scancode_queue_size
	and #SQ_LENGTH - 1
	tay
	pla
	sta scancode_mod_queue,y
	txa
	sta scancode_key_queue,y
	inc scancode_queue_size
@queue_full:
	lda #0
	sta break
	sta ext_e0
	sta ext_e1
	jmp @next


; Return the next scancode up/down event in A/X.
; Returns $0000 if no event is queued.
keyboard_get_event:
	lda scancode_queue_size
	bne :+
	tax
	rts
:
	phy				; Disable IRQs and save Y.
	php
	sei
	
	lda scancode_queue_index	; Advance the queue index.
	pha
	ina
	and #SQ_LENGTH - 1
	sta scancode_queue_index
	
	dec scancode_queue_size
	
	ply
	lda scancode_key_queue,y
	tax
	lda scancode_mod_queue,y

	plp				; Restore Y and IRQ state.
	ply
	rts
