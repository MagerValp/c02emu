	.include "hcm-prefix.s"

; expected result: $01DD = 0x6E
test03:
	LDA #$4B
	LSR
	ASL
	
	STA $50
	ASL $50
	ASL $50
	LSR $50
	LDA $50
	
	LDX $50
	ORA #$C9
	STA $60
	ASL $4C,X
	LSR $4C,X
	LSR $4C,X
	LDA $4C,X
	
	LDX $60
	ORA #$41
	STA $012E
	LSR $0100,X
	LSR $0100,X
	ASL $0100,X
	LDA $0100,X
	
	LDX $012E
	ORA #$81
	STA $0100,X
	LSR $0136
	LSR $0136
	ASL $0136
	LDA $0100,X
	
	; rol & ror
	
	ROL
	ROL
	ROR
	STA $70
	
	LDX $70
	ORA #$03
	STA $0C,X
	ROL $C0
	ROR $C0
	ROR $C0
	LDA $0C,X
	
	LDX $C0
	STA $D0
	ROL $75,X
	ROL $75,X
	ROR $75,X
	LDA $D0
	
	LDX $D0
	STA $0100,X
	ROL $01B7
	ROL $01B7
	ROL $01B7
	ROR $01B7
	LDA $0100,X
	
	LDX $01B7
	STA $01DD
	ROL $0100,X
	ROR $0100,X
	ROR $0100,X
	
; CHECK test03
	LDA $01DD
	CMP $0203
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
