	.include "hcm-prefix.s"

; expected result: $33 = 0x42
test12:
	CLC
	LDA #$42
	BCC runstuff
check12:
	STA $33
	BCS t12end
runstuff:
	LDA #>check12
	PHA
	LDA #<check12
	PHA
	SEC
	PHP
	CLC
	RTI
t12end:

; CHECK test12
	LDA $33
	CMP #<check12
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
