	.include "keyboard.i"
	

	.export keymap_translate


	.zeropage

map_ptr:	.res 2


	.code

keymap_translate:
	bit #KM_Cmd
	beq :+
@no_key:
	lda #0
	rts
:
	cpx #$80		; No extend codes produce printable chars.
	bcs @no_key
	
	bit #KM_Ctrl
	bne @ctrl
	
	phy			; Don't modify Y.
	
	pha			; Save modifier state.
	
	and #3			; Bit 0 is shift, bit 1 is alt.
	lsr			; Multiply by 128 and add to keymap address.
	ora #>keymap_unshifted
	sta map_ptr + 1
	lda #0
	ror
	sta map_ptr
	txa			; Load scancode into Y.
	tay
	lda (map_ptr),y
	tax			; Read character and save in X.
	
	pla			; Check for caps lock.
	bit #KM_Caps
	bne @caps

	ply
	txa
	rts
@caps:	
	ply
	lda ascii_caps,x
	rts

@ctrl:
	lda keymap_ctrl,x
	rts


	.rodata

	.align $100

keymap_unshifted:
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,  $09,  '`',    0
	.byte    0,    0,    0,    0,    0,  'q',  '1',    0
	.byte    0,    0,  'z',  's',  'a',  'w',  '2',    0
	.byte    0,  'c',  'x',  'd',  'e',  '4',  '3',    0
	.byte    0,  ' ',  'v',  'f',  't',  'r',  '5',    0
	.byte    0,  'n',  'b',  'h',  'g',  'y',  '6',    0
	.byte    0,    0,  'm',  'j',  'u',  '7',  '8',    0
	.byte    0,  ',',  'k',  'i',  'o',  '0',  '9',    0
	.byte    0,  '.',  '/',  'l',  ';',  'p',  '-',    0
	.byte    0,    0,  $27,    0,  '[',  '=',    0,    0
	.byte    0,    0,  $0a,  ']',    0,  $5c,    0,    0
	.byte    0,  '<',    0,    0,    0,    0,  $08,    0
	.byte    0,  '1',    0,  '4',  '7',    0,    0,    0
	.byte  '0',  '.',  '2',  '5',  '6',  '8',  $1b,    0
	.byte    0,  '+',  '3',  '-',  '*',  '9',    0,    0

keymap_shifted:
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,  $09,  '~',    0
	.byte    0,    0,    0,    0,    0,  'Q',  '!',    0
	.byte    0,    0,  'Z',  'S',  'A',  'W',  '@',    0
	.byte    0,  'C',  'X',  'D',  'E',  '$',  '#',    0
	.byte    0,  ' ',  'V',  'F',  'T',  'R',  '%',    0
	.byte    0,  'N',  'B',  'H',  'G',  'Y',  '^',    0
	.byte    0,    0,  'M',  'J',  'U',  '&',  '*',    0
	.byte    0,  '<',  'K',  'I',  'O',  ')',  '(',    0
	.byte    0,  '>',  '?',  'L',  ':',  'P',  '_',    0
	.byte    0,    0,  '"',    0,  '{',  '+',    0,    0
	.byte    0,    0,  $0a,  '}',    0,  '|',    0,    0
	.byte    0,  '>',    0,    0,    0,    0,  $08,    0
	.byte    0,  '1',    0,  '4',  '7',    0,    0,    0
	.byte  '0',  '.',  '2',  '5',  '6',  '8',  $1b,    0
	.byte    0,  '+',  '3',  '-',  '*',  '9',    0,    0

keymap_alt:
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0

keymap_alt_shifted:
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0

keymap_ctrl:
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,  $11,    0,    0
	.byte    0,    0,  $1a,  $13,  $01,  $17,    0,    0
	.byte    0,  $03,  $18,  $04,  $05,    0,    0,    0
	.byte    0,    0,  $16,  $06,  $14,  $12,    0,    0
	.byte    0,  $0e,  $02,  $08,  $07,  $19,    0,    0
	.byte    0,    0,  $0d,  $0a,  $15,    0,    0,    0
	.byte    0,    0,  $0b,  $09,  $0f,    0,    0,    0
	.byte    0,    0,    0,  $0c,    0,  $10,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,  $1b,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0
	.byte    0,    0,    0,    0,    0,    0,    0,    0

ascii_caps:
	.byte  $00,  $01,  $02,  $03,  $04,  $05,  $06,  $07
	.byte  $08,  $09,  $0a,  $0b,  $0c,  $0d,  $0e,  $0f
	.byte  $10,  $11,  $12,  $13,  $14,  $15,  $16,  $17
	.byte  $18,  $19,  $1a,  $1b,  $1c,  $1d,  $1e,  $1f
	.byte  ' ',  '!',  '"',  '#',  '$',  '%',  '&',  $27
	.byte  '(',  ')',  '*',  '+',  ',',  '-',  '.',  '/'
	.byte  '0',  '1',  '2',  '3',  '4',  '5',  '6',  '7'
	.byte  '8',  '9',  ':',  ';',  '<',  '=',  '>',  '?'
	.byte  '@',  'A',  'B',  'C',  'D',  'E',  'F',  'G'
	.byte  'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O'
	.byte  'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W'
	.byte  'X',  'Y',  'Z',  '[',  $5c,  ']',  '^',  '_'
	.byte  '`',  'A',  'B',  'C',  'D',  'E',  'F',  'G'
	.byte  'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O'
	.byte  'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W'
	.byte  'X',  'Y',  'Z',  '{',  '|',  '}',  '~', $7f
