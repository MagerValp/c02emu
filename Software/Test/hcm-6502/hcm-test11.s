	.include "hcm-prefix.s"

; expected result: $30 = 0x29
test11:

; RESET TO CARRY = 0 & ZERO = 0
	ADC #$01
	
	LDA #$27
	ADC #$01
	SEC
	PHP
	CLC
	PLP
	ADC #$00
	PHA
	LDA #$00
	PLA
	STA $30
	
; CHECK test11
	LDA $30
	CMP $020B
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
