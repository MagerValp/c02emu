//
//  c02emu.c
//  c02emu
//
//  Created by Pelle on 2015-01-07.
//  Copyright (c) 2015 Per Olofsson. All rights reserved.
//

#include <stdlib.h>
#include <string.h>
#include "c02emu.h"


// Include both headers and implementation, as the declarations are static.
#include "c02emu_uops.h"
#include "c02emu_uops.c"
#include "c02emu_optable.h"
#include "c02emu_optable.c"
#include "c02emu_private.h"
#include "c02emu_private.c"

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
    
    state->io.display.mode = C02EMU_DISPLAY_MODE_TEXT_80X50;
    state->io.display.base = 0x000000;
    state->io.display.irq_mask = 0;
    state->io.display.irq_status = 0;
    
    c02emuReset(state);
    
    state->cycle_ctr = 0;
    state->line_ctr = 0;
    state->frame_ctr = 0;
    
    state->monitor.trace = 0;
    state->monitor.debug_output = true;
    
    return state;
}


void c02emuDestroy(C02EmuState *state) {
    free(state);
}


void c02emuLoadROM(C02EmuState *state, const void *data, size_t size) {
    if (size > sizeof(state->mem.rom)) {
        size = sizeof(state->mem.rom);
    }
    memcpy(state->mem.rom + sizeof(state->mem.rom) - size, data, size);
}


void c02emuReset(C02EmuState *state) {
    for (int i = 0; i < 0x0e; i++) {
        state->io.mmu.page[i] = i;
    }
    state->io.mmu.page[0x0e] = 0xa0;
    state->io.mmu.page[0x0f] = 0xff;
    
    state->io.keyboard.index = 0;
    state->io.keyboard.size = 0;
    
    state->cpu.op.opcode = 0;
    if (state->monitor.trace & C02EMU_TRACE_CPU) {
        fprintf(stderr, "PC = %04x RESET\n", state->cpu.pc);
    }
    state->cpu.op.uop_list = irq_op_table[OP_RESET];
    state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
    state->cpu.op.address_fixup = false;
    state->cpu.op.decimal_fixup = false;
    state->cpu.op.irq_active = false;
    state->cpu.op.nmi_active = false;
}


void c02emuStepCycle(C02EmuState *state) {
    cpu_step_cycle(state);
    io_step_cycle(state);
}


C02EmuReturnReason c02emuRun(C02EmuState *state) {
    unsigned int current_frame = state->frame_ctr;
    
    for (;;) {
        cpu_step_cycle(state);
        io_step_cycle(state);
        if (state->cpu.op.cycle == C02EMU_OP_STOPPED) {
            return C02EMU_CPU_STOPPED;
        } else if (current_frame != state->frame_ctr) {
            return C02EMU_FRAME_READY;
        }
    }
}


const C02EmuOutput c02emuGetOutput(C02EmuState *state) {
    C02EmuOutput output;
    output.display.mode = state->io.display.mode;
    output.display.data = &state->mem.ram[state->io.display.base];
    return output;
}


void c02emuKeyboardQueueInsert(C02EmuState *state, const Byte *bytes, size_t count) {
    for (int i = 0; i < count; i++) {
        if (state->io.keyboard.size == sizeof(state->io.keyboard.queue)) {
            if (i > 0) {
                state->io.keyboard.queue[state->io.keyboard.index - 1] = 0;
            }
            return;
        }
        state->io.keyboard.queue[state->io.keyboard.index + state->io.keyboard.size] = bytes[i];
        state->io.keyboard.size += 1;
    }
}


#include "c02emu_util.c"
