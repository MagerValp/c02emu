	.include "hcm-prefix.s"

; expected result: $40 = 0x33
test05:
	LDA #$35
	
	TAX
	DEX
	DEX
	INX
	TXA
	
	TAY
	DEY
	DEY
	INY
	TYA
	
	TAX
	LDA #$20
	TXS
	LDX #$10
	TSX
	TXA
	
	STA $40
	
; CHECK test05
	LDA $40
	CMP $0205
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
