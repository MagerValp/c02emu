//
//  c02emu_uops.c
//  c02emu
//
//  Created by Pelle on 2015-01-09.
//  Copyright (c) 2015 Per Olofsson. All rights reserved.
//

#ifndef __c02emu__c02emu_uops_c__
#define __c02emu__c02emu_uops_c__


#include "c02emu_private.h"
#include "c02emu_uops.h"


#define CLN() state->cpu.status &= ~flag_n
#define SEN() state->cpu.status |= flag_n
#define CLV() state->cpu.status &= ~flag_v
#define SEV() state->cpu.status |= flag_v
#define CLB() state->cpu.status &= ~flag_b
#define SEB() state->cpu.status |= flag_b
#define CLD() state->cpu.status &= ~flag_d
#define SED() state->cpu.status |= flag_d
#define CLI() state->cpu.status &= ~flag_i
#define SEI() state->cpu.status |= flag_i
#define CLZ() state->cpu.status &= ~flag_z
#define SEZ() state->cpu.status |= flag_z
#define CLC() state->cpu.status &= ~flag_c
#define SEC() state->cpu.status |= flag_c


#define SETNZ(VAL) do { \
    Byte v = (VAL); \
    if (v == 0) { SEZ(); } else { CLZ(); } \
    if (v & 0x80) { SEN(); } else { CLN(); } \
} while (0)


#define A (state->cpu.a)
#define X (state->cpu.x)
#define Y (state->cpu.y)
#define P (state->cpu.status)
#define S (state->cpu.stack)
#define PC (state->cpu.pc)

#define ALU (state->cpu.op.alu)
#define AD (state->cpu.op.ad.w)
#define ADL (state->cpu.op.ad.b.l)
#define ADH (state->cpu.op.ad.b.h)
#define BA (state->cpu.op.ba.w)
#define BAL (state->cpu.op.ba.b.l)
#define BAH (state->cpu.op.ba.b.h)


#define OP_DONE() do { \
    state->cpu.op.cycle = C02EMU_OP_FETCH; \
} while (0)


static bool flag_set(C02EmuState *state, Byte flag) {
    return (P & flag) != 0;
}

static bool flag_clear(C02EmuState *state, Byte flag) {
    return (P & flag) == 0;
}



#pragma mark Addressing modes


static void u_zp_ad(C02EmuState *state) {
    AD = cpu_read(state, PC++);
}

static void u_abs_adl(C02EmuState *state) {
    ADL = cpu_read(state, PC++);
}

static void u_abs_adh(C02EmuState *state) {
    ADH = cpu_read(state, PC++);
}

static void u_izp(C02EmuState *state) {
    BA = cpu_read(state, PC++);
}

static void u_izp_adl(C02EmuState *state) {
    ADL = cpu_read(state, BA);
}

static void u_izp_adh(C02EmuState *state) {
    ADH = cpu_read(state, (BA + 1) & 0xff);
}

static void u_izx_adl(C02EmuState *state) {
    ADL = cpu_read(state, (BA + X) & 0xff);
}

static void u_izx_adh(C02EmuState *state) {
    ADH = cpu_read(state, (BA + X + 1) & 0xff);
}

static void u_rel_bra(C02EmuState *state) {
    if (state->cpu.op.address_fixup == false &&
        (PC + (int8_t)BAL) >> 8 != PC >> 8) {
        cpu_read(state, (PC & 0xff00) | ((PC + (int8_t)BAL) & 0xff));
        state->cpu.op.address_fixup = true;
    } else {
        PC += (int8_t)BAL;
        cpu_read(state, PC);
        OP_DONE();
    }
}

static void u_rel_bbra(C02EmuState *state) {
    cpu_read(state, (PC & 0xff00) | ((PC + (int8_t)BAL) & 0xff));
}

static void u_zpr_ba(C02EmuState *state) {
    BA = cpu_read(state, PC++);
}

static void u_rmw_ad(C02EmuState *state) {
    ALU = cpu_read(state, AD);
}

static void u_rmw_adx(C02EmuState *state) {
    if (state->cpu.op.address_fixup == true) {
        ALU = cpu_read(state, AD + X);
    } else {
        if (ADL + X < 256) {
            ALU = cpu_read(state, AD + X);
            state->cpu.op.cycle += 1;
        } else {
            cpu_read(state, PC - 1);
            state->cpu.op.address_fixup = true;
        }
    }
}

static void u_rmw_adlx(C02EmuState *state) {
    ALU = cpu_read(state, (ADL + X) & 0xff);
}



#pragma mark Stack ops


static Byte u_pull(C02EmuState *state) {
    return cpu_read(state, 0x0100 | ++S);
}

static void u_push(C02EmuState *state, Byte byte) {
    cpu_write(state, 0x0100 | S--, byte);
}



#pragma mark Dummy access


static void u_dum_sdec(C02EmuState *state) {
    cpu_read(state, 0x0100 | S--);
}

static void u_dum_ad(C02EmuState *state) {
    cpu_read(state, AD);
}

static void u_dum_adl(C02EmuState *state) {
    cpu_read(state, ADL);
}

static void u_dum_adx(C02EmuState *state) {
    cpu_read(state, PC - 1);
    //cpu_read(state, (ADH << 8) | ((ADL + X) & 0xff));
}

static void u_dum_adxreal(C02EmuState *state) {
    cpu_read(state, AD + X);
}

static void u_dum_adlx(C02EmuState *state) {
    cpu_read(state, (ADL + X) & 0xff);
}

static void u_dum_ady(C02EmuState *state) {
    cpu_read(state, PC - 1);
    //cpu_read(state, (ADH << 8) | ((ADL + Y) & 0xff));
}

static void u_dum_bal(C02EmuState *state) {
    cpu_read(state, BAL);
}

static void u_dum_s(C02EmuState *state) {
    cpu_read(state, 0x0100 | S);
}

static void u_dum_pc(C02EmuState *state) {
    cpu_read(state, PC);
}



#pragma mark Function synths


#define SYNTHESIZE_imp(OP) \
static void u_##OP##_imp(C02EmuState *state) { \
    cpu_read(state, PC); \
    op_##OP(state); \
}

#define SYNTHESIZE_imm(OP) \
static void u_##OP##_imm(C02EmuState *state) { \
    op_##OP(state, cpu_read(state, PC++)); \
}

#define SYNTHESIZE_ad(OP) \
static void u_##OP##_ad(C02EmuState *state) { \
    op_##OP(state, cpu_read(state, AD)); \
}

#define SYNTHESIZE_w_ad(OP) \
static void u_##OP##_ad(C02EmuState *state) { \
    op_##OP(state, AD); \
}

#define SYNTHESIZE_rmw_ad(OP) \
static void u_##OP##_ad(C02EmuState *state) { \
    op_##OP(state, AD); \
}

#define SYNTHESIZE_r_adx(OP) \
static void u_##OP##_adx(C02EmuState *state) { \
    if (!state->cpu.op.address_fixup && X + ADL >= 256) { \
        cpu_read(state, PC - 1); \
        state->cpu.op.address_fixup = true; \
    } else { \
        op_##OP(state, cpu_read(state, AD + X)); \
    } \
}

#define SYNTHESIZE_rmw_adx(OP) \
static void u_##OP##_adx(C02EmuState *state) { \
    op_##OP(state, AD + X); \
}

#define SYNTHESIZE_rmw_adlx(OP) \
static void u_##OP##_adlx(C02EmuState *state) { \
    op_##OP(state, (ADL + X) & 0xff); \
}

#define SYNTHESIZE_r_ady(OP) \
static void u_##OP##_ady(C02EmuState *state) { \
    if (!state->cpu.op.address_fixup && Y + ADL >= 256) { \
        cpu_read(state, PC - 1); \
        state->cpu.op.address_fixup = true; \
    } else { \
        op_##OP(state, cpu_read(state, AD + Y)); \
    } \
}

#define SYNTHESIZE_w_adx(OP) \
static void u_##OP##_adx(C02EmuState *state) { \
    op_##OP(state, AD + X); \
}

#define SYNTHESIZE_w_ady(OP) \
static void u_##OP##_ady(C02EmuState *state) { \
    op_##OP(state, AD + Y); \
}

#define SYNTHESIZE_alx(OP) \
static void u_##OP##_alx(C02EmuState *state) { \
    op_##OP(state, cpu_read(state, (ADL + X) & 0xff)); \
}

#define SYNTHESIZE_w_alx(OP) \
static void u_##OP##_alx(C02EmuState *state) { \
    op_##OP(state, (ADL + X) & 0xff); \
}

#define SYNTHESIZE_aly(OP) \
static void u_##OP##_aly(C02EmuState *state) { \
    op_##OP(state, cpu_read(state, (ADL + Y) & 0xff)); \
}

#define SYNTHESIZE_w_aly(OP) \
static void u_##OP##_aly(C02EmuState *state) { \
    op_##OP(state, (ADL + Y) & 0xff); \
}



#pragma mark IRQs


static void u_IRQ_incpc(C02EmuState *state) {
    cpu_read(state, PC++);
}

static void u_IRQ_pch(C02EmuState *state) {
    u_push(state, PC >> 8);
}

static void u_IRQ_pcl(C02EmuState *state) {
    u_push(state, PC & 0xff);
}

static void u_IRQ_p(C02EmuState *state) {
    u_push(state, P & ~flag_b);
    P = (P | flag_i) & ~flag_d;
}

static void u_IRQ_adl(C02EmuState *state) {
    Addr vector = 0xfffe;
    
    if (state->cpu.op.nmi_active) {
        vector = 0xfffa;
    }
    PC = (PC & 0xff00) | cpu_read(state, vector);
}

static void u_IRQ_adh(C02EmuState *state) {
    Addr vector = 0xfffe;
    
    if (state->cpu.op.nmi_active) {
        vector = 0xfffa;
        state->cpu.op.nmi_active = false;
    }
    PC = (PC & 0x00ff) | (cpu_read(state, vector + 1) << 8);
    OP_DONE();
}

static void u_NMI_adl(C02EmuState *state) {
    PC = (PC & 0xff00) | cpu_read(state, 0xfffa);
}

static void u_NMI_adh(C02EmuState *state) {
    state->cpu.op.nmi_active = false;
    PC = (PC & 0x00ff) | (cpu_read(state, 0xfffb) << 8);
    OP_DONE();
}

static void u_RESET_p(C02EmuState *state) {
    u_dum_sdec(state);
    P = (P | flag_i) & ~flag_d;
}

static void u_RESET_adl(C02EmuState *state) {
    PC = (PC & 0xff00) | cpu_read(state, 0xfffc);
}

static void u_RESET_adh(C02EmuState *state) {
    PC = (PC & 0x00ff) | (cpu_read(state, 0xfffd) << 8);
    OP_DONE();
}



#pragma mark Opcodes


static void op_ADC(C02EmuState *state, Byte byte) {
    uint16_t result, lo;
    Byte carry = P & flag_c;
    
    if (state->cpu.op.decimal_fixup == true) {
        OP_DONE();
        return;
    }
    
    if (P & flag_d) {
        // Calculate result of low nybble.
        lo = (A & 0x0f) + (byte & 0x0f) + carry;
        if (lo >= 0x0a) {
            lo = ((lo + 0x06) & 0x0f) + 0x10;
        }
        // Partial result of both nybbles.
        result = (A & 0xf0) + (byte & 0xf0) + lo;
        // Calculate V before decimal adjusting high nybble.
        if (~(A ^ byte) & (A ^ result) & 0x80) {
            SEV();
        } else {
            CLV();
        }
        // Decimal adjust high nybble.
        if (result >= 0xa0) {
            result = result + 0x60;
        }
        
    } else {
        result = A + byte + carry;
        if (~(A ^ byte) & (A ^ result) & 0x80) {
            SEV();
        } else {
            CLV();
        }
    }
    
    A = result;
    SETNZ(A);
    if (result >= 0x100) {
        SEC();
    } else {
        CLC();
    }
    
    if (state->cpu.op.decimal_fixup == false && (P & flag_d)) {
        state->cpu.op.decimal_fixup = true;
    } else {
        OP_DONE();
    }
}
static void u_ADC_imm(C02EmuState *state) {
    if (state->cpu.op.decimal_fixup == true) {
        cpu_read(state, PC - 1);
        OP_DONE();
    } else {
        op_ADC(state, cpu_read(state, PC++));
    }
}
SYNTHESIZE_ad(ADC)
SYNTHESIZE_r_adx(ADC)
SYNTHESIZE_r_ady(ADC)
SYNTHESIZE_alx(ADC)


static void op_AND(C02EmuState *state, Byte byte) {
    A &= byte;
    SETNZ(A);
    OP_DONE();
}
SYNTHESIZE_imm(AND)
SYNTHESIZE_ad(AND)
SYNTHESIZE_r_adx(AND)
SYNTHESIZE_r_ady(AND)
SYNTHESIZE_alx(AND)


static void u_ASL_imp(C02EmuState *state) {
    cpu_read(state, PC);
    if (A & 0x80) {
        SEC();
    } else {
        CLC();
    }
    A <<= 1;
    SETNZ(A);
    OP_DONE();
}
static void op_ASL(C02EmuState *state, Addr addr) {
    if (ALU & 0x80) {
        SEC();
    } else {
        CLC();
    }
    ALU <<= 1;
    SETNZ(ALU);
    cpu_write(state, addr, ALU);
    OP_DONE();
}
SYNTHESIZE_rmw_ad(ASL)
SYNTHESIZE_rmw_adx(ASL)
SYNTHESIZE_rmw_adlx(ASL)


#define SYNTHESIZE_bbr(BIT) \
static void u_BBR##BIT##_zpr(C02EmuState *state) { \
    if ((cpu_read(state, ADL) & 1<<BIT) == 0) { \
        PC += (int8_t)BAL; \
    } \
    OP_DONE(); \
}
SYNTHESIZE_bbr(0)
SYNTHESIZE_bbr(1)
SYNTHESIZE_bbr(2)
SYNTHESIZE_bbr(3)
SYNTHESIZE_bbr(4)
SYNTHESIZE_bbr(5)
SYNTHESIZE_bbr(6)
SYNTHESIZE_bbr(7)


#define SYNTHESIZE_bbs(BIT) \
static void u_BBS##BIT##_zpr(C02EmuState *state) { \
    if ((cpu_read(state, ADL) & 1<<BIT) != 0) { \
        PC += (int8_t)BAL; \
    } \
    OP_DONE(); \
}
SYNTHESIZE_bbs(0)
SYNTHESIZE_bbs(1)
SYNTHESIZE_bbs(2)
SYNTHESIZE_bbs(3)
SYNTHESIZE_bbs(4)
SYNTHESIZE_bbs(5)
SYNTHESIZE_bbs(6)
SYNTHESIZE_bbs(7)


static void u_BCC_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_clear(state, flag_c)) {
        OP_DONE();
    }
}


static void u_BCS_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_set(state, flag_c)) {
        OP_DONE();
    }
}


static void u_BEQ_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_set(state, flag_z)) {
        OP_DONE();
    }
}


static void op_BIT(C02EmuState *state, Byte byte) {
    P = (P & 0x3f) | (byte & 0xc0);
    if ((A & byte) == 0) {
        SEZ();
    } else {
        CLZ();
    }
    OP_DONE();
}
static void u_BIT_imm(C02EmuState *state) {
    if ((A & cpu_read(state, PC++)) == 0) {
        SEZ();
    } else {
        CLZ();
    }
    OP_DONE();
}
SYNTHESIZE_ad(BIT)
SYNTHESIZE_r_adx(BIT)
SYNTHESIZE_alx(BIT)


static void u_BMI_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_set(state, flag_n)) {
        OP_DONE();
    }
}


static void u_BNE_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_clear(state, flag_z)) {
        OP_DONE();
    }
}


static void u_BPL_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_clear(state, flag_n)) {
        OP_DONE();
    }
}


static void u_BRA_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
}


static void u_BRK_p(C02EmuState *state) {
    u_push(state, P | flag_b);
    P = (P | flag_i) & ~flag_d;
}


static void u_BVC_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_clear(state, flag_v)) {
        OP_DONE();
    }
}


static void u_BVS_rel(C02EmuState *state) {
    BA = cpu_read(state, PC++);
    if (!flag_set(state, flag_v)) {
        OP_DONE();
    }
}


static void op_CLC(C02EmuState *state) {
    CLC();
    OP_DONE();
}
SYNTHESIZE_imp(CLC)


static void op_CLD(C02EmuState *state) {
    CLD();
    OP_DONE();
}
SYNTHESIZE_imp(CLD)


static void op_CLI(C02EmuState *state) {
    CLI();
    OP_DONE();
}
SYNTHESIZE_imp(CLI)


static void op_CLV(C02EmuState *state) {
    CLV();
    OP_DONE();
}
SYNTHESIZE_imp(CLV)



static void op_CMP(C02EmuState *state, Byte byte) {
    if (A < byte) {
        CLC();
    } else {
        SEC();
    }
    SETNZ((A - byte) & 0xff);
    OP_DONE();
}
SYNTHESIZE_imm(CMP)
SYNTHESIZE_ad(CMP)
SYNTHESIZE_r_adx(CMP)
SYNTHESIZE_r_ady(CMP)
SYNTHESIZE_alx(CMP)


static void op_CPX(C02EmuState *state, Byte byte) {
    if (X < byte) {
        CLC();
    } else {
        SEC();
    }
    SETNZ((X - byte) & 0xff);
    OP_DONE();
}
SYNTHESIZE_imm(CPX)
SYNTHESIZE_ad(CPX)


static void op_CPY(C02EmuState *state, Byte byte) {
    if (Y < byte) {
        CLC();
    } else {
        SEC();
    }
    SETNZ((Y - byte) & 0xff);
    OP_DONE();
}
SYNTHESIZE_imm(CPY)
SYNTHESIZE_ad(CPY)


static void u_DEC_imp(C02EmuState *state) {
    cpu_read(state, PC);
    A -= 1;
    SETNZ(A);
    OP_DONE();
}
static void op_DEC(C02EmuState *state, Addr addr) {
    ALU -= 1;
    SETNZ(ALU);
    cpu_write(state, addr, ALU);
    OP_DONE();
}
SYNTHESIZE_rmw_ad(DEC)
SYNTHESIZE_rmw_adx(DEC)
SYNTHESIZE_rmw_adlx(DEC)


static void op_DEX(C02EmuState *state) {
    SETNZ(--X);
    OP_DONE();
}
SYNTHESIZE_imp(DEX)


static void op_DEY(C02EmuState *state) {
    SETNZ(--Y);
    OP_DONE();
}
SYNTHESIZE_imp(DEY)


static void op_EOR(C02EmuState *state, Byte byte) {
    A ^= byte;
    SETNZ(A);
    OP_DONE();
}
SYNTHESIZE_imm(EOR)
SYNTHESIZE_ad(EOR)
SYNTHESIZE_r_adx(EOR)
SYNTHESIZE_r_ady(EOR)
SYNTHESIZE_alx(EOR)


static void u_INC_imp(C02EmuState *state) {
    cpu_read(state, PC);
    A += 1;
    SETNZ(A);
    OP_DONE();
}
static void op_INC(C02EmuState *state, Addr addr) {
    ALU += 1;
    SETNZ(ALU);
    cpu_write(state, addr, ALU);
    OP_DONE();
}
SYNTHESIZE_rmw_ad(INC)
SYNTHESIZE_rmw_adx(INC)
SYNTHESIZE_rmw_adlx(INC)


static void op_INX(C02EmuState *state) {
    SETNZ(++X);
    OP_DONE();
}
SYNTHESIZE_imp(INX)


static void op_INY(C02EmuState *state) {
    SETNZ(++Y);
    OP_DONE();
}
SYNTHESIZE_imp(INY)


static void u_JMP_adh(C02EmuState *state) {
    ADH = cpu_read(state, PC++);
    PC = AD;
    OP_DONE();
}
static void u_JMP_bal(C02EmuState *state) {
    BAL = cpu_read(state, AD);
}
static void u_JMP_bah(C02EmuState *state) {
    BAH = cpu_read(state, (AD & 0xff00) | ((ADL + 1) & 0xff));
}
static void u_JMP_ba(C02EmuState *state) {
    BAH = cpu_read(state, AD + 1);
    PC = BA;
    OP_DONE();
}
static void u_JMP_balx(C02EmuState *state) {
    BAL = cpu_read(state, AD);
}
static void u_JMP_bahx(C02EmuState *state) {
    BAL = cpu_read(state, AD + X);
}
static void u_JMP_bax(C02EmuState *state) {
    BAH = cpu_read(state, AD + X + 1);
    PC = BA;
    OP_DONE();
}


static void u_JSR_pcl(C02EmuState *state) {
    u_push(state, PC & 0xff);
}
static void u_JSR_pch(C02EmuState *state) {
    u_push(state, PC >> 8);
}


static void op_LDA(C02EmuState *state, Byte byte) {
    A = byte;
    SETNZ(A);
    OP_DONE();
}
SYNTHESIZE_imm(LDA)
SYNTHESIZE_ad(LDA)
SYNTHESIZE_r_adx(LDA)
SYNTHESIZE_r_ady(LDA)
SYNTHESIZE_alx(LDA)


static void op_LDX(C02EmuState *state, Byte byte) {
    X = byte;
    SETNZ(byte);
    OP_DONE();
}
SYNTHESIZE_imm(LDX)
SYNTHESIZE_ad(LDX)
SYNTHESIZE_r_ady(LDX)
SYNTHESIZE_aly(LDX)


static void op_LDY(C02EmuState *state, Byte byte) {
    Y = byte;
    SETNZ(Y);
    OP_DONE();
}
SYNTHESIZE_imm(LDY)
SYNTHESIZE_ad(LDY)
SYNTHESIZE_r_adx(LDY)
SYNTHESIZE_alx(LDY)


static void u_LSR_imp(C02EmuState *state) {
    cpu_read(state, PC);
    if (A & 0x01) {
        SEC();
    } else {
        CLC();
    }
    A >>= 1;
    SETNZ(A);
    OP_DONE();
}
static void op_LSR(C02EmuState *state, Addr addr) {
    if (ALU & 0x01) {
        SEC();
    } else {
        CLC();
    }
    ALU >>= 1;
    SETNZ(ALU);
    cpu_write(state, addr, ALU);
    OP_DONE();
}
SYNTHESIZE_rmw_ad(LSR)
SYNTHESIZE_rmw_adx(LSR)
SYNTHESIZE_rmw_adlx(LSR)


static void op_NOP(C02EmuState *state, Byte byte) {
    OP_DONE();
}
static void u_NOP_imp(C02EmuState *state) {
    cpu_read(state, PC);
    OP_DONE();
}
static void u_NOP_abs8(C02EmuState *state) {
    cpu_read(state, PC - 1);
    OP_DONE();
}
SYNTHESIZE_imm(NOP)
SYNTHESIZE_ad(NOP)
SYNTHESIZE_alx(NOP)


static void op_ORA(C02EmuState *state, Byte byte) {
    A |= byte;
    SETNZ(A);
    OP_DONE();
}
SYNTHESIZE_imm(ORA)
SYNTHESIZE_ad(ORA)
SYNTHESIZE_r_adx(ORA)
SYNTHESIZE_r_ady(ORA)
SYNTHESIZE_alx(ORA)


static void u_PHA_imp(C02EmuState *state) {
    u_push(state, A);
    OP_DONE();
}


static void u_PHX_imp(C02EmuState *state) {
    u_push(state, X);
    OP_DONE();
}


static void u_PHY_imp(C02EmuState *state) {
    u_push(state, Y);
    OP_DONE();
}


static void u_PHP_imp(C02EmuState *state) {
    u_push(state, P | flag_b);
    OP_DONE();
}


static void u_PLA_imp(C02EmuState *state) {
    A = u_pull(state);
    SETNZ(A);
    OP_DONE();
}


static void u_PLX_imp(C02EmuState *state) {
    X = u_pull(state);
    SETNZ(X);
    OP_DONE();
}


static void u_PLY_imp(C02EmuState *state) {
    Y = u_pull(state);
    SETNZ(Y);
    OP_DONE();
}


static void u_PLP_imp(C02EmuState *state) {
    P = u_pull(state) | flag_1;
    OP_DONE();
}


#define SYNTHESIZE_rmb(BIT) \
static void u_RMB##BIT##_ad(C02EmuState *state) { \
    ALU &= ~(1 << (BIT)); \
    cpu_write(state, AD, ALU); \
    OP_DONE(); \
}
SYNTHESIZE_rmb(0)
SYNTHESIZE_rmb(1)
SYNTHESIZE_rmb(2)
SYNTHESIZE_rmb(3)
SYNTHESIZE_rmb(4)
SYNTHESIZE_rmb(5)
SYNTHESIZE_rmb(6)
SYNTHESIZE_rmb(7)


static void u_ROL_imp(C02EmuState *state) {
    Byte carry = P & flag_c;
    
    cpu_read(state, PC);
    if (A & 0x80) {
        SEC();
    } else {
        CLC();
    }
    A = (A << 1) | carry;
    SETNZ(A);
    OP_DONE();
}
static void op_ROL(C02EmuState *state, Addr addr) {
    Byte carry = P & flag_c;
    
    if (ALU & 0x80) {
        SEC();
    } else {
        CLC();
    }
    ALU = (ALU << 1) | carry;
    SETNZ(ALU);
    cpu_write(state, addr, ALU);
    OP_DONE();
}
SYNTHESIZE_rmw_ad(ROL)
SYNTHESIZE_rmw_adx(ROL)
SYNTHESIZE_rmw_adlx(ROL)


static void u_ROR_imp(C02EmuState *state) {
    Byte carry = P & flag_c;
    
    cpu_read(state, PC);
    if (A & 0x01) {
        SEC();
    } else {
        CLC();
    }
    A >>= 1;
    if (carry) {
        A |= 0x80;
    }
    SETNZ(A);
    OP_DONE();
}
static void op_ROR(C02EmuState *state, Addr addr) {
    Byte carry = P & flag_c;
    
    if (ALU & 0x01) {
        SEC();
    } else {
        CLC();
    }
    ALU >>= 1;
    if (carry) {
        ALU |= 0x80;
    }
    SETNZ(ALU);
    cpu_write(state, addr, ALU);
    OP_DONE();
}
SYNTHESIZE_rmw_ad(ROR)
SYNTHESIZE_rmw_adx(ROR)
SYNTHESIZE_rmw_adlx(ROR)


static void u_RTI_p(C02EmuState *state) {
    P = u_pull(state) | flag_1;
}
static void u_RTI_pcl(C02EmuState *state) {
    PC = (PC & 0xff00) | u_pull(state);
}
static void u_RTI_pch(C02EmuState *state) {
    PC = (PC & 0x00ff) | (u_pull(state) << 8);
    OP_DONE();
}


static void u_RTS_pcl(C02EmuState *state) {
    PC = (PC & 0xff00) | u_pull(state);
}
static void u_RTS_pch(C02EmuState *state) {
    PC = (PC & 0x00ff) | (u_pull(state) << 8);
}
static void u_RTS_incpc(C02EmuState *state) {
    cpu_read(state, PC++);
    OP_DONE();
}


static void op_SBC(C02EmuState *state, Byte byte) {
    int16_t result;
    int16_t lo;
    int16_t carry = P & flag_c;
    
    if (state->cpu.op.decimal_fixup == true) {
        OP_DONE();
        return;
    }
    
    if (P & flag_d) {
        
        // First perform a binary SBC to calculate V and C.
        
        result = A - byte - 1 + carry;
        
        if ((A ^ byte) & (A ^ result) & 0x80) {
            SEV();
        } else {
            CLV();
        }
        
        if (!(result & 0x100)) {
            SEC();
        } else {
            CLC();
        }
        
        // Then perform decimal SBC to calculate actual result.
        
        lo = (A & 0x0f) - (byte & 0x0f) + carry - 1;
        result = A - byte + carry - 1;
        if (result < 0) {
            result -= 0x60;
        }
        if (lo < 0) {
            result -= 0x06;
        }
        
    } else {
        result = A - byte - 1 + carry;
        
        if ((A ^ byte) & (A ^ result) & 0x80) {
            SEV();
        } else {
            CLV();
        }
        
        if (result < 0) {
            CLC();
        } else {
            SEC();
        }
    }
    A = result;
    SETNZ(A);
    
    if (state->cpu.op.decimal_fixup == false && (P & flag_d)) {
        state->cpu.op.decimal_fixup = true;
    } else {
        OP_DONE();
    }
}
static void u_SBC_imm(C02EmuState *state) {
    if (state->cpu.op.decimal_fixup == true) {
        cpu_read(state, PC - 1);
        OP_DONE();
    } else {
        op_SBC(state, cpu_read(state, PC++));
    }
}
SYNTHESIZE_ad(SBC)
SYNTHESIZE_r_adx(SBC)
SYNTHESIZE_r_ady(SBC)
SYNTHESIZE_alx(SBC)


static void op_SEC(C02EmuState *state) {
    SEC();
    OP_DONE();
}
SYNTHESIZE_imp(SEC)


static void op_SED(C02EmuState *state) {
    SED();
    OP_DONE();
}
SYNTHESIZE_imp(SED)


static void op_SEI(C02EmuState *state) {
    SEI();
    OP_DONE();
}
SYNTHESIZE_imp(SEI)


#define SYNTHESIZE_smb(BIT) \
static void u_SMB##BIT##_ad(C02EmuState *state) { \
    ALU |= 1 << (BIT); \
    cpu_write(state, AD, ALU); \
    OP_DONE(); \
}
SYNTHESIZE_smb(0)
SYNTHESIZE_smb(1)
SYNTHESIZE_smb(2)
SYNTHESIZE_smb(3)
SYNTHESIZE_smb(4)
SYNTHESIZE_smb(5)
SYNTHESIZE_smb(6)
SYNTHESIZE_smb(7)


static void op_STA(C02EmuState *state, Addr addr) {
    cpu_write(state, addr, A);
    OP_DONE();
}
SYNTHESIZE_w_ad(STA)
SYNTHESIZE_w_adx(STA)
SYNTHESIZE_w_ady(STA)
SYNTHESIZE_w_alx(STA)


static void u_STP_imp(C02EmuState *state) {
    cpu_read(state, PC);
    state->cpu.op.stop_notified = false;
    state->cpu.op.cycle = C02EMU_OP_STOPPED;
}


static void op_STX(C02EmuState *state, Addr addr) {
    cpu_write(state, addr, X);
    OP_DONE();
}
SYNTHESIZE_w_ad(STX)
SYNTHESIZE_w_aly(STX)


static void op_STY(C02EmuState *state, Addr addr) {
    cpu_write(state, addr, Y);
    OP_DONE();
}
SYNTHESIZE_w_ad(STY)
SYNTHESIZE_w_alx(STY)


static void op_STZ(C02EmuState *state, Addr addr) {
    cpu_write(state, addr, 0);
    OP_DONE();
}
SYNTHESIZE_w_ad(STZ)
SYNTHESIZE_w_adx(STZ)
SYNTHESIZE_w_alx(STZ)


static void op_TAX(C02EmuState *state) {
    X = A;
    SETNZ(X);
    OP_DONE();
}
SYNTHESIZE_imp(TAX)


static void op_TAY(C02EmuState *state) {
    Y = A;
    SETNZ(Y);
    OP_DONE();
}
SYNTHESIZE_imp(TAY)


static void u_TRB_ad(C02EmuState *state) {
    if ((A & ALU) == 0) {
        SEZ();
    } else {
        CLZ();
    }
    ALU &= ~A;
    cpu_write(state, AD, ALU);
    OP_DONE();
}


static void u_TSB_ad(C02EmuState *state) {
    if ((A & ALU) == 0) {
        SEZ();
    } else {
        CLZ();
    }
    ALU |= A;
    cpu_write(state, AD, ALU);
    OP_DONE();
}


static void op_TSX(C02EmuState *state) {
    X = S;
    SETNZ(X);
    OP_DONE();
}
SYNTHESIZE_imp(TSX)


static void op_TXA(C02EmuState *state) {
    A = X;
    SETNZ(A);
    OP_DONE();
}
SYNTHESIZE_imp(TXA)


static void op_TXS(C02EmuState *state) {
    S = X;
    OP_DONE();
}
SYNTHESIZE_imp(TXS)


static void op_TYA(C02EmuState *state) {
    A = Y;
    SETNZ(A);
    OP_DONE();
}
SYNTHESIZE_imp(TYA)


static void u_WAI_imp(C02EmuState *state) {
    cpu_read(state, PC);
    state->cpu.op.cycle = C02EMU_OP_WAITING;
}


#endif
