	.include "hcm-prefix.s"

; expected result: $15 = 0x7F
test07:
	; prepare memory	
	LDA #$00
	STA $34
	LDA #$FF
	STA $0130
	LDA #$99
	STA $019D
	LDA #$DB
	STA $0199
	LDA #$2F
	STA $32
	LDA #$32
	STA $4F
	LDA #$30
	STA $33
	LDA #$70
	STA $AF
	LDA #$18
	STA $30
	
	; imm
	CMP #$18
	BEQ beq1 ; taken
	AND #$00 ; not done
beq1:
	; zpg
	ORA #$01
	CMP $30
	BNE bne1 ; taken
	AND #$00 ; not done
bne1:
	; abs
	LDX #$00
	CMP $0130
	BEQ beq2 ; not taken
	STA $40
	LDX $40
beq2:
	; zpx
	CMP $27,X
	BNE bne2 ; not taken
	ORA #$84
	STA $41
	LDX $41
bne2:
	; abx
	AND #$DB
	CMP $0100,X
	BEQ beq3 ; taken
	AND #$00 ; not done
beq3:
	; aby
	STA $42
	LDY $42
	AND #$00
	CMP $0100,Y
	BNE bne3 ; taken
	ORA #$0F ; not done
bne3:
	; idx
	STA $43
	LDX $43
	ORA #$24
	CMP ($40,X)
	BEQ beq4 ; not taken
	ORA #$7F
beq4:
	; idy
	STA $44
	LDY $44 
	EOR #$0F
	CMP ($33),Y
	BNE bne4 ; not taken
	LDA $44
	STA $15
bne4:

; CHECK test07
	LDA $15
	CMP $0207
	BEQ pass
	JMP fail
	
	.include "hcm-suffix.s"
