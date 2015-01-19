//
//  c02emu_util.c
//  c02emu
//
//  Created by Per Olofsson on 2015-01-16.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//


#ifndef __c02emu__c02emu_util_c__
#define __c02emu__c02emu_util_c__


#include "c02emu_private.h"
#include "c02emu_util.h"


C02EmuCPURegs c02emuCPURegs(C02EmuState *state) {
    C02EmuCPURegs regs;
    
    regs.a = state->cpu.a;
    regs.x = state->cpu.x;
    regs.y = state->cpu.y;
    regs.stack = state->cpu.stack;
    regs.status = state->cpu.status;
    regs.pc = state->cpu.pc;
    
    return regs;
}


C02EmuCPUState c02emuCPUState(C02EmuState *state) {
    C02EmuCPUState cpu_state;
    
    cpu_state.ir = state->cpu.op.opcode;
    cpu_state.op_state = state->cpu.op.cycle;
    
    return cpu_state;
}


C02EmuDisplayState c02emuDisplayState(C02EmuState *state) {
    C02EmuDisplayState display_state;
    
    display_state.cycle_ctr = state->cycle_ctr;
    display_state.line_ctr = state->line_ctr;
    display_state.frame_ctr = state->frame_ctr;
    
    return display_state;
}


Byte c02emuCPURead(C02EmuState *state, Addr addr) {
    return cpu_read(state, addr);
}


void c02emuCPUWrite(C02EmuState *state, Addr addr, Byte byte) {
    cpu_write(state, addr, byte);
}


#endif
