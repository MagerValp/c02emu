	.include "hcm-prefix.s"

; expected result: $022A = 0x55
test00:
   	LDA #85
	LDX #42
	LDY #115
	STA $81
	LDA #$01
	STA $61
	LDA #$7E
	LDA $81
	STA $0910
	LDA #$7E
	LDA $0910
	STA $56,X
	LDA #$7E
	LDA $56,X
	STY $60
	STA ($60),Y
	LDA #$7E
	LDA ($60),Y
	STA $07ff,X
	LDA #$7E
	LDA $07ff,X
	STA $07ff,Y
	LDA #$7E
	LDA $07ff,Y
	STA ($36,X)
	LDA #$7E
	LDA ($36,X)
	STX $50
	LDX $60
	LDY $50
	STX $0913
	LDX #$22
	LDX $0913
	STY $0914
	LDY #$99
	LDY $0914
	STY $2D,X
	STX $77,Y
	LDY #$99
	LDY $2D,X
	LDX #$22
	LDX $77,Y
	LDY #$99
	LDY $08A0,X
	LDX #$22
	LDX $08A1,Y
	STA $0200,X
	
; CHECK test00:
	LDA $022A
	CMP $0200
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
