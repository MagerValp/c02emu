	.include "hcm-prefix.s"

; expected result: $40 = 0x42
test04:
	LDA #<final
	STA $20
	LDA #>final
	STA $21
	LDA #$00
	ORA #$03
	JMP jump1
	ORA #$FF ; not done
jump1:
	ORA #$30
	JSR subr
	ORA #$42
	JMP ($0020)
	ORA #$FF ; not done
subr:
	STA $30
	LDX $30
	LDA #$00
	RTS
final:
	STA $0D,X
	
; CHECK test04
	LDA $40
	CMP $0204
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
