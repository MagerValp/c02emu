	.include "hcm-prefix.s"

; expected result: $30 = 0xCE
test10:

; RESET TO CARRY = 0 & OVERFLOW = 0
	ADC #$00

	LDA #$99
	ADC #$87
	CLC
	NOP
	BCC t10bcc1 ; taken
	ADC #$60 ; not done
	ADC #$93 ; not done
t10bcc1:
	SEC
	NOP
	BCC t10bcc2 ; not taken
	CLV
t10bcc2:
	BVC t10bvc1 ; taken
	LDA #$00 ; not done
t10bvc1: 
	ADC #$AD
	NOP
	STA $30
	
; CHECK test10
	LDA $30
	CMP $020A
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
