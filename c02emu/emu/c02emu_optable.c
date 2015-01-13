//
//  c02emu_optable.c
//  c02emu
//
//  Created by Pelle on 2015-01-09.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//


#ifndef __c02emu__c02emu_optable_c__
#define __c02emu__c02emu_optable_c__


#include <assert.h>
#include "c02emu_uops.h"
#include "c02emu_optable.h"


#include <stdio.h>

static void u_error(C02EmuState *state) {
    fprintf(stderr, "CPU decoding error for opcode %02x in cycle %d\n",
            state->cpu.op.opcode, state->cpu.op.cycle);
    fprintf(stderr, "ad = %04x, ba = %04x, address_fixup = %s\n",
            state->cpu.op.ad.w, state->cpu.op.ba.w,
            state->cpu.op.address_fixup ? "true" : "false");
    fprintf(stderr, "A = %02x, X = %02x, Y = %02x, P = %02x, S = %02x, PC = %04x\n",
            state->cpu.a, state->cpu.x, state->cpu.y,
            state->cpu.status, state->cpu.stack, state->cpu.pc);
    assert(0);
}


#define PAD u_error
#define PAD2 PAD, PAD
#define PAD3 PAD2, PAD
#define PAD4 PAD3, PAD
#define PAD5 PAD4, PAD
#define CMAX2 PAD5
#define CMAX3 PAD4
#define CMAX4 PAD3
#define CMAX5 PAD2
#define CMAX6 PAD
#define CMAX7

#define UNIMPLEMENTED { PAD, PAD, PAD, PAD, PAD, PAD }

// ALU read ops.
#define R_IMM(OP)     { u_##OP##_imm, CMAX2 }
#define R_ABS(OP)     { u_abs_adl,    u_abs_adh,    u_##OP##_ad,  CMAX4 }
#define R_ABX(OP)     { u_abs_adl,    u_abs_adh,    u_##OP##_adx, u_##OP##_adx, CMAX5 }
#define R_ABY(OP)     { u_abs_adl,    u_abs_adh,    u_##OP##_ady, u_##OP##_ady, CMAX5 }
#define R_ZP(OP)      { u_zp_ad,      u_##OP##_ad,  CMAX3 }
#define R_ZPX(OP)     { u_zp_ad,      u_dum_adl,    u_##OP##_alx, CMAX4 }
#define R_ZPY(OP)     { u_zp_ad,      u_dum_adl,    u_##OP##_aly, CMAX4 }
#define R_IZP(OP)     { u_izp,        u_izp_adl,    u_izp_adh,    u_##OP##_ad,  CMAX5 }
#define R_IZX(OP)     { u_izp,        u_dum_bal,    u_izx_adl,    u_izx_adh,    u_##OP##_ad,  CMAX6 }
#define R_IZY(OP)     { u_izp,        u_izp_adl,    u_izp_adh,    u_##OP##_ady, u_##OP##_ady, CMAX6 }

// Decimal mode fixup for ADC and SBC.
#define RD_IMM(OP)    { u_##OP##_imm, u_##OP##_imm, CMAX3 }
#define RD_ABS(OP)    { u_abs_adl,    u_abs_adh,    u_##OP##_ad,  u_##OP##_ad,  CMAX5 }
#define RD_ABX(OP)    { u_abs_adl,    u_abs_adh,    u_##OP##_adx, u_##OP##_adx, u_##OP##_adx, CMAX6 }
#define RD_ABY(OP)    { u_abs_adl,    u_abs_adh,    u_##OP##_ady, u_##OP##_ady, u_##OP##_ady, CMAX6 }
#define RD_ZP(OP)     { u_zp_ad,      u_##OP##_ad,  u_##OP##_ad,  CMAX4 }
#define RD_ZPX(OP)    { u_zp_ad,      u_dum_adl,    u_##OP##_alx, u_##OP##_alx, CMAX5 }
#define RD_ZPY(OP)    { u_zp_ad,      u_dum_adl,    u_##OP##_aly, u_##OP##_aly, CMAX5 }
#define RD_IZP(OP)    { u_izp,        u_izp_adl,    u_izp_adh,    u_##OP##_ad,  u_##OP##_ad,  CMAX6 }
#define RD_IZX(OP)    { u_izp,        u_dum_bal,    u_izx_adl,    u_izx_adh,    u_##OP##_ad,  u_##OP##_ad,  CMAX7 }
#define RD_IZY(OP)    { u_izp,        u_izp_adl,    u_izp_adh,    u_##OP##_ady, u_##OP##_ady, u_##OP##_ady, CMAX7 }

// ALU write ops.
#define W_ABS(OP)     R_ABS(OP)
#define W_ABX(OP)     { u_abs_adl,    u_abs_adh,    u_dum_adx,    u_##OP##_adx, CMAX5 }
#define W_ABY(OP)     { u_abs_adl,    u_abs_adh,    u_dum_ady,    u_##OP##_ady, CMAX5 }
#define W_IZP(OP)     R_IZP(OP)
#define W_IZX(OP)     R_IZX(OP)
#define W_IZY(OP)     { u_izp,        u_izp_adl,    u_izp_adh,    u_dum_ady,    u_##OP##_ady, CMAX6 }
#define W_ZP(OP)      R_ZP(OP)
#define W_ZPX(OP)     R_ZPX(OP)
#define W_ZPY(OP)     R_ZPY(OP)

// Implied ops.
#define I_IMP(OP)     { u_##OP##_imp, CMAX2 }
#define R_IMP(OP)     I_IMP(OP)

// Relative branches.
#define B_REL(OP)     { u_##OP##_rel, u_rel_bra,    u_rel_bra,    CMAX4 }

// Stack ops.
#define PULL_IMP(OP)  { u_dum_pc,     u_dum_s,      u_##OP##_imp, CMAX4 }
#define PUSH_IMP(OP)  { u_dum_pc,     u_##OP##_imp, CMAX3 }

// ALU RMW ops.
#define RMW_IMP(OP)   I_IMP(OP)
#define RMW_ABS(OP)   { u_abs_adl,    u_abs_adh,    u_rmw_ad,     u_dum_ad,     u_##OP##_ad,   CMAX6 }
#define RMW_ABX(OP)   { u_abs_adl,    u_abs_adh,    u_dum_adx,    u_rmw_adx,    u_dum_adxreal, u_##OP##_adx, CMAX7 }
#define RMW_ZP(OP)    { u_zp_ad,      u_rmw_ad,     u_dum_ad,     u_##OP##_ad,  CMAX5 }
#define RMW_ZPX(OP)   { u_zp_ad,      u_dum_adlx,   u_rmw_adlx,   u_dum_adlx,   u_##OP##_adlx, CMAX6 }

// Jump, IRQ, and return ops.
#define BRK_IMP(OP)   { u_IRQ_incpc,  u_IRQ_pch,    u_IRQ_pcl,    u_BRK_p,      u_IRQ_adl,    u_IRQ_adh,     CMAX7 }
#define JMP_ABS(OP)   { u_abs_adl,    u_JMP_adh,    CMAX3 }
#define JMP_IAX(OP)   { u_abs_adl,    u_abs_adh,    u_JMP_balx,   u_JMP_bahx,   u_JMP_bax,    CMAX6 }
#define JMP_IND(OP)   { u_abs_adl,    u_abs_adh,    u_JMP_bal,    u_JMP_bah,    u_JMP_ba,     CMAX6 }
#define JSR_ABS(OP)   { u_abs_adl,    u_dum_s,      u_JSR_pch,    u_JSR_pcl,    u_JMP_adh,    CMAX6 }
#define RTI_IMP(OP)   { u_dum_pc,     u_dum_s,      u_RTI_p,      u_RTI_pcl,    u_RTI_pch,    CMAX6 }
#define RTS_IMP(OP)   { u_dum_pc,     u_dum_s,      u_RTS_pcl,    u_RTS_pch,    u_RTS_incpc,  CMAX6 }

#define STOP_IMP(OP)  { u_dum_pc,     u_STP_imp,    CMAX3 }
#define WAIT_IMP(OP)  { u_dum_pc,     u_WAI_imp,    CMAX3 }


// Reset, NMI, IRQ.
static C02EmuUop irq_op_table[3][7] = {
    { u_dum_pc,     u_dum_pc,     u_dum_sdec,   u_dum_sdec,   u_RESET_p,    u_RESET_adl,  u_RESET_adh },
    { u_dum_pc,     u_dum_pc,     u_IRQ_pch,    u_IRQ_pcl,    u_IRQ_p,      u_NMI_adl,    u_NMI_adh   },
    { u_dum_pc,     u_dum_pc,     u_IRQ_pch,    u_IRQ_pcl,    u_IRQ_p,      u_IRQ_adl,    u_IRQ_adh   },
};


static C02EmuUop op_table[256][6] = {
    // 00 - 0f
    BRK_IMP(BRK),   // BRK 7
    R_IZX(ORA),     // ORA izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    RMW_ZP(TSB),    // TSB zp 5
    R_ZP(ORA),      // ORA zp 3
    RMW_ZP(ASL),    // ASL zp 5
    RMW_ZP(RMB0),   // RMB0 zp 5
    PUSH_IMP(PHP),  // PHP 3
    R_IMM(ORA),     // ORA imm 2
    RMW_IMP(ASL),   // ASL 2
    R_IMP(NOP),     // NOP
    RMW_ABS(TSB),   // TSB abs 6
    R_ABS(ORA),     // ORA abs 4
    RMW_ABS(ASL),   // ASL abs 6
    B_REL(BBR0),    // BBR0 rel 2*
    // 10 - 1f
    B_REL(BPL),     // BPL rel 2*
    R_IZY(ORA),     // ORA izy 5*
    R_IZP(ORA),     // ORA izp 5
    R_IMP(NOP),     // NOP
    RMW_ZP(TRB),    // TRB zp 5
    R_ZPX(ORA),     // ORA zpx 4
    RMW_ZPX(ASL),   // ASL zpx 6
    RMW_ZP(RMB1),   // RMB1 zp 5
    I_IMP(CLC),     // CLC 2
    R_ABY(ORA),     // ORA aby 4*
    RMW_IMP(INC),   // INC 2
    R_IMP(NOP),     // NOP
    RMW_ABS(TRB),   // TRB abs 6
    R_ABX(ORA),     // ORA abx 4*
    RMW_ABX(ASL),   // ASL abx 6*
    B_REL(BBR1),    // BBR1 rel 2*
    // 20 - 2f
    JSR_ABS(JSR),   // JSR abs 6
    R_IZX(AND),     // AND izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    R_ZP(BIT),      // BIT zp 3
    R_ZP(AND),      // AND zp 3
    RMW_ZP(ROL),    // ROL zp 5
    RMW_ZP(RMB2),   // RMB2 zp 5
    PULL_IMP(PLP),  // PLP 4
    R_IMM(AND),     // AND imm 2
    RMW_IMP(ROL),   // ROL 2
    R_IMP(NOP),     // NOP
    R_ABS(BIT),     // BIT abs 4
    R_ABS(AND),     // AND abs 4
    RMW_ABS(ROL),   // ROL abs 6
    B_REL(BBR2),    // BBR2 rel 2*
    // 30 - 3f
    B_REL(BMI),     // BMI rel 2*
    R_IZY(AND),     // AND izy 5*
    R_IZP(AND),     // AND izp 5
    R_IMP(NOP),     // NOP
    R_ZPX(BIT),     // BIT zpx 4
    R_ZPX(AND),     // AND zpx 4
    RMW_ZPX(ROL),   // ROL zpx 6
    RMW_ZP(RMB3),   // RMB3 zp 5
    I_IMP(SEC),     // SEC 2
    R_ABY(AND),     // AND aby 4*
    RMW_IMP(DEC),   // DEC 2
    R_IMP(NOP),     // NOP
    R_ABX(BIT),     // BIT abx 4*
    R_ABX(AND),     // AND abx 4*
    RMW_ABX(ROL),   // ROL abx 6*
    B_REL(BBR3),    // BBR3 rel 2*
    // 40 - 4f
    RTI_IMP(RTI),   // RTI 6
    R_IZX(EOR),     // EOR izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    R_ZP(NOP),      // NOP zp 3
    R_ZP(EOR),      // EOR zp 3
    RMW_ZP(LSR),    // LSR zp 5
    RMW_ZP(RMB4),   // RMB4 zp 5
    PUSH_IMP(PHA),  // PHA 3
    R_IMM(EOR),     // EOR imm 2
    RMW_IMP(LSR),   // LSR 2
    R_IMP(NOP),     // NOP
    JMP_ABS(JMP),   // JMP abs 3
    R_ABS(EOR),     // EOR abs 4
    RMW_ABS(LSR),   // LSR abs 6
    B_REL(BBR4),    // BBR4 rel 2*
    // 50 - 5f
    B_REL(BVC),     // BVC rel 2*
    R_IZY(EOR),     // EOR izy 5*
    R_IZP(EOR),     // EOR izp 5
    R_IMP(NOP),     // NOP
    R_ZPX(NOP),     // NOP zpx 4
    R_ZPX(EOR),     // EOR zpx 4
    RMW_ZPX(LSR),   // LSR zpx 6
    RMW_ZP(RMB5),   // RMB5 zp 5
    I_IMP(CLI),     // CLI 2
    R_ABY(EOR),     // EOR aby 4*
    PUSH_IMP(PHY),  // PHY 3
    R_IMP(NOP),     // NOP
    R_IMP(NOP),     // NOP
    R_ABX(EOR),     // EOR abx 4*
    RMW_ABX(LSR),   // LSR abx 6*
    B_REL(BBR5),    // BBR5 rel 2*
    // 60 - 6f
    RTS_IMP(RTS),   // RTS 6
    RD_IZX(ADC),    // ADC izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    W_ZP(STZ),      // STZ zp 3
    RD_ZP(ADC),     // ADC zp 3
    RMW_ZP(ROR),    // ROR zp 5
    RMW_ZP(RMB6),   // RMB6 zp 5
    PULL_IMP(PLA),  // PLA 4
    RD_IMM(ADC),    // ADC imm 2
    RMW_IMP(ROR),   // ROR 2
    R_IMP(NOP),     // NOP
    JMP_IND(JMP),   // JMP ind 6
    RD_ABS(ADC),    // ADC abs 4
    RMW_ABS(ROR),   // ROR abs 6
    B_REL(BBR6),    // BBR6 rel 2*
    // 70 - 7f
    B_REL(BVS),     // BVS rel 2*
    RD_IZY(ADC),    // ADC izy 5*
    RD_IZP(ADC),    // ADC izp 5
    R_IMP(NOP),     // NOP
    W_ZPX(STZ),     // STZ zpx 4
    RD_ZPX(ADC),    // ADC zpx 4
    RMW_ZPX(ROR),   // ROR zpx 6
    RMW_ZP(RMB7),   // RMB7 zp 5
    I_IMP(SEI),     // SEI 2
    RD_ABY(ADC),    // ADC aby 4*
    PULL_IMP(PLY),  // PLY 4
    R_IMP(NOP),     // NOP
    JMP_IAX(JMP),   // JMP iax 6
    RD_ABX(ADC),    // ADC abx 4*
    RMW_ABX(ROR),   // ROR abx 6*
    B_REL(BBR7),    // BBR7 rel 2*
    // 80 - 8f
    B_REL(BRA),     // BRA rel 3*
    W_IZX(STA),     // STA izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    W_ZP(STY),      // STY zp 3
    W_ZP(STA),      // STA zp 3
    W_ZP(STX),      // STX zp 3
    RMW_ZP(SMB0),   // SMB0 zp 5
    I_IMP(DEY),     // DEY 2
    R_IMM(BIT),     // BIT imm 2
    I_IMP(TXA),     // TXA 2
    R_IMP(NOP),     // NOP
    W_ABS(STY),     // STY abs 4
    W_ABS(STA),     // STA abs 4
    W_ABS(STX),     // STX abs 4
    B_REL(BBS0),    // BBS0 rel 2*
    // 90 - 9f
    B_REL(BCC),     // BCC rel 2*
    W_IZY(STA),     // STA izy 6
    W_IZP(STA),     // STA izp 5
    R_IMP(NOP),     // NOP
    W_ZPX(STY),     // STY zpx 4
    W_ZPX(STA),     // STA zpx 4
    W_ZPY(STX),     // STX zpy 4
    RMW_ZP(SMB1),   // SMB1 zp 5
    I_IMP(TYA),     // TYA 2
    W_ABY(STA),     // STA aby 5
    I_IMP(TXS),     // TXS 2
    R_IMP(NOP),     // NOP
    W_ABS(STZ),     // STZ abs 4
    W_ABX(STA),     // STA abx 5
    W_ABX(STZ),     // STZ abx 5
    B_REL(BBS1),    // BBS1 rel 2*
    // a0 - af
    R_IMM(LDY),     // LDY imm 2
    R_IZX(LDA),     // LDA izx 6
    R_IMM(LDX),     // LDX imm 2
    R_IMP(NOP),     // NOP
    R_ZP(LDY),      // LDY zp 3
    R_ZP(LDA),      // LDA zp 3
    R_ZP(LDX),      // LDX zp 3
    RMW_ZP(SMB2),   // SMB2 zp 5
    I_IMP(TAY),     // TAY 2
    R_IMM(LDA),     // LDA imm 2
    I_IMP(TAX),     // TAX 2
    R_IMP(NOP),     // NOP
    R_ABS(LDY),     // LDY abs 4
    R_ABS(LDA),     // LDA abs 4
    R_ABS(LDX),     // LDX abs 4
    B_REL(BBS2),    // BBS2 rel 2*
    // b0 - bf
    B_REL(BCS),     // BCS rel 2*
    R_IZY(LDA),     // LDA izy 5*
    R_IZP(LDA),     // LDA izp 5
    R_IMP(NOP),     // NOP
    R_ZPX(LDY),     // LDY zpx 4
    R_ZPX(LDA),     // LDA zpx 4
    R_ZPY(LDX),     // LDX zpy 4
    RMW_ZP(SMB3),   // SMB3 zp 5
    I_IMP(CLV),     // CLV 2
    R_ABY(LDA),     // LDA aby 4*
    I_IMP(TSX),     // TSX 2
    R_IMP(NOP),     // NOP
    R_ABX(LDY),     // LDY abx 4*
    R_ABX(LDA),     // LDA abx 4*
    R_ABY(LDX),     // LDX aby 4*
    B_REL(BBS3),    // BBS3 rel 2*
    // c0 - cf
    R_IMM(CPY),     // CPY imm 2
    R_IZX(CMP),     // CMP izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    R_ZP(CPY),      // CPY zp 3
    R_ZP(CMP),      // CMP zp 3
    RMW_ZP(DEC),    // DEC zp 5
    RMW_ZP(SMB4),   // SMB4 zp 5
    I_IMP(INY),     // INY 2
    R_IMM(CMP),     // CMP imm 2
    I_IMP(DEX),     // DEX 2
    WAIT_IMP(WAI),  // WAI 3
    R_ABS(CPY),     // CPY abs 4
    R_ABS(CMP),     // CMP abs 4
    RMW_ABS(DEC),   // DEC abs 6
    B_REL(BBS4),    // BBS4 rel 2*
    // d0 - df
    B_REL(BNE),     // BNE rel 2*
    R_IZY(CMP),     // CMP izy 5*
    R_IZP(CMP),     // CMP izp 5
    R_IMP(NOP),     // NOP
    R_ZPX(NOP),     // NOP zpx 4
    R_ZPX(CMP),     // CMP zpx 4
    RMW_ZPX(DEC),   // DEC zpx 6
    RMW_ZP(SMB5),   // SMB5 zp 5
    I_IMP(CLD),     // CLD 2
    R_ABY(CMP),     // CMP aby 4*
    PUSH_IMP(PHX),  // PHX 3
    STOP_IMP(STP),  // STP 3
    R_IMP(NOP),     // NOP
    R_ABX(CMP),     // CMP abx 4*
    RMW_ABX(DEC),   // DEC abx 6*
    B_REL(BBS5),    // BBS5 rel 2*
    // e0 - ef
    R_IMM(CPX),     // CPX imm 2
    RD_IZX(SBC),    // SBC izx 6
    R_IMM(NOP),     // NOP imm 2
    R_IMP(NOP),     // NOP
    R_ZP(CPX),      // CPX zp 3
    RD_ZP(SBC),     // SBC zp 3
    RMW_ZP(INC),    // INC zp 5
    RMW_ZP(SMB6),   // SMB6 zp 5
    I_IMP(INX),     // INX 2
    RD_IMM(SBC),    // SBC imm 2
    R_IMP(NOP),     // NOP 2
    R_IMP(NOP),     // NOP
    R_ABS(CPX),     // CPX abs 4
    RD_ABS(SBC),    // SBC abs 4
    RMW_ABS(INC),   // INC abs 6
    B_REL(BBS6),    // BBS6 rel 2*
    // f0 - ff
    B_REL(BEQ),     // BEQ rel 2*
    RD_IZY(SBC),    // SBC izy 5*
    RD_IZP(SBC),    // SBC izp 5
    R_IMP(NOP),     // NOP
    R_ZPX(NOP),     // NOP zpx 4
    RD_ZPX(SBC),    // SBC zpx 4
    RMW_ZPX(INC),   // INC zpx 6
    RMW_ZP(SMB7),   // SMB7 zp 5
    I_IMP(SED),     // SED 2
    RD_ABY(SBC),    // SBC aby 4*
    PULL_IMP(PLX),  // PLX 4
    R_IMP(NOP),     // NOP
    R_IMP(NOP),     // NOP
    RD_ABX(SBC),    // SBC abx 4*
    RMW_ABX(INC),   // INC abx 6*
    B_REL(BBS7),    // BBS7 rel 2*
};


#endif
