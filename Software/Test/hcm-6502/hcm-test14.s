	.include "hcm-prefix.s"

; expect result: $60 = 0x42
test14:
	; !!! NOTICE: BRK doesn't work in this
	; simulator, so commented instructions 
	; are what should be executed...
	;JMP pass_intrp
	LDA #$41
	STA $60
	;RTI
	;pass_intrp:
	;LDA #$FF
	;STA $60
	;BRK (two bytes)
	INC $60
	
; CHECK test14
	LDA $60
	CMP $020E
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
