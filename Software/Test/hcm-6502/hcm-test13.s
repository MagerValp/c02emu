	.include "hcm-prefix.s"

; expected result: $21 = 0x6C (simulator)
;                  $21 = 0x0C (ours)
test13:

; RESET TO CARRY = 0 & ZERO = 0
	ADC #$01
	
	SEI
	SED
	PHP
	PLA
	STA $20
	CLI
	CLD
	PHP
	PLA
	ADC $20
	STA $21

; CHECK test13
	LDA $21
	CMP $020D
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
