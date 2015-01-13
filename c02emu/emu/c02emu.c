//
//  c02emu.c
//  c02emu
//
//  Created by Pelle on 2015-01-07.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

#include <stdlib.h>
#include <string.h>
#include "c02emu.h"


// Include both headers and implementation, as the declarations are static.
#include "c02emu_private.h"
#include "c02emu_private.c"
#include "c02emu_uops.h"
#include "c02emu_uops.c"
#include "c02emu_optable.h"
#include "c02emu_optable.c"

#include "c02emu_util.h"



#pragma mark • Public functions


C02EmuState *c02emuCreate(void) {
    C02EmuState *state = malloc(sizeof(C02EmuState));
    if (state == NULL) {
        return NULL;
    }
    
    state->cpu.a = 0xaa;
    state->cpu.x = 0x00;
    state->cpu.y = 0x00;
    state->cpu.status = flag_1 | flag_z;
    state->cpu.stack = 0x00;
    state->cpu.pc = 0x00ff;
    
    memset(state->mem.ram, 0x00, sizeof(state->mem.ram));
    memset(state->mem.rom, 0xdb, sizeof(state->mem.rom));
    
    memset(state->io.display.ram, 0xff, sizeof(state->io.display.ram));
    state->io.display.page = 0x00;
    
    c02emuReset(state);
    
    state->cycle_counter = 0;
    state->frame_counter = 0;
    state->vbl_counter = cycles_per_frame(state->frame_counter);
    
    state->monitor.trace_cpu = false;
    state->monitor.trace_ram = false;
    
    return state;
}


void c02emuDestroy(C02EmuState *state) {
    free(state);
}


void c02emuLoadROM(C02EmuState *state, const void *data, size_t size) {
    if (size > sizeof(state->mem.rom)) {
        size = sizeof(state->mem.rom);
    }
    memcpy(state->mem.rom, data, size);
}


void c02emuReset(C02EmuState *state) {
    for (int i = 0; i < 0x0e; i++) {
        state->io.mmu.page[i] = i;
    }
    state->io.mmu.page[0x0e] = 0xfe;
    state->io.mmu.page[0x0f] = 0xff;
    
    state->cpu.op.opcode = 0;
    if (state->monitor.trace_cpu) {
        fprintf(stderr, "PC = %04x RESET\n", state->cpu.pc);
    }
    state->cpu.op.uop_list = irq_op_table[OP_RESET];
    state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
    state->cpu.op.address_fixup = false;
    state->cpu.op.decimal_fixup = false;
}


C02EmuReturnReason c02emuRun(C02EmuState *state) {
    Byte op;
    
    for (;;) {
        
        // This is a simple instruction decoding state machine, with
        // op.cycle keeping track of the current step.
        
        if (state->cpu.op.cycle == C02EMU_OP_DONE) {
            
            if (!(state->cpu.status & flag_i)) {
                // Evaluate IRQs.
            }
            // Evaluate NMIs.
            
            if (state->monitor.trace_cpu) {
                fputs("  PC   A  X  Y  S  nv1bdizc\n", stderr);
                fprintf(stderr, ".;%04x %02x %02x %02x %02x %d%d1%d%d%d%d%d\n",
                        state->cpu.pc,
                        state->cpu.a,
                        state->cpu.x,
                        state->cpu.y,
                        state->cpu.stack,
                        (state->cpu.status & flag_n) >> 7,
                        (state->cpu.status & flag_v) >> 6,
                        (state->cpu.status & flag_b) >> 4,
                        (state->cpu.status & flag_d) >> 3,
                        (state->cpu.status & flag_i) >> 2,
                        (state->cpu.status & flag_z) >> 1,
                        (state->cpu.status & flag_c));
            }
            
            op = raw_mem_read(state, (state->cpu.pc)++);
            state->cpu.op.opcode = op;
            if (state->monitor.trace_cpu) {
                fprintf(stderr, "PC = %04x OP = %02x\n", (state->cpu.pc - 1) & 0xffff, op);
            }
            state->cpu.op.uop_list = op_table[op];
            state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
            state->cpu.op.address_fixup = false;
            state->cpu.op.decimal_fixup = false;
            
        } else if(state->cpu.op.cycle == C02EMU_OP_STOPPED) {
        
            if (!state->cpu.op.stop_notified) {
                state->cpu.op.stop_notified = true;
                return C02EMU_CPU_STOPPED;
            }
        
        } else if(state->cpu.op.cycle == C02EMU_OP_WAITING) {
            
            if (!(state->cpu.status & flag_i)) {
                // Evaluate IRQs.
            } else {
                // Evaluate IRQs, but continue at PC instead of jumping to vector.
            }
            // Evaluate NMIs.
            
        } else {
            
            state->cpu.op.uop_list[state->cpu.op.cycle](state);
            if (state->cpu.op.cycle < C02EMU_OP_DONE) {
                state->cpu.op.cycle += 1;
            }
        }
        
        state->cycle_counter += 1;
        if (state->cycle_counter >= state->vbl_counter) {
            state->frame_counter += 1;
            state->vbl_counter += cycles_per_frame(state->frame_counter);
            return C02EMU_FRAME_READY;
        }
    }
}


const C02EmuOutput c02emuGetOutput(C02EmuState *state) {
    C02EmuOutput output;
    output.display.mode = C02EMU_DISPLAY_MODE_TEXT_80X50;
    output.display.data = state->io.display.ram;
    return output;
}


C02EmuCPURegs *c02emuCPURegs(C02EmuState *state) {
    return (C02EmuCPURegs *)&state->cpu;
}


Byte c02emuCPURead(C02EmuState *state, Addr addr) {
    return raw_mem_read(state, addr);
}

void c02emuCPUWrite(C02EmuState *state, Addr addr, Byte byte) {
    raw_mem_write(state, addr, byte);
}
