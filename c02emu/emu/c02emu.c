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
    
    state->phase = C02EMU_PHASE_CPU;
    
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
    
    c02emuReset(state);
    
    state->cycle_ctr = 0;
    state->line_ctr = 0;
    state->frame_ctr = 0;
    
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


C02EmuReturnReason c02emuStepCycle(C02EmuState *state) {
    C02EmuReturnReason reason;
    
    if (state->phase == C02EMU_PHASE_CPU) {
        state->phase = C02EMU_PHASE_IO;
        reason = cpu_step_cycle(state);
        if (reason != C02EMU_CYCLE_STEPPED) {
            return reason;
        }
    }
    
    if (state->phase == C02EMU_PHASE_IO) {
        state->phase = C02EMU_PHASE_CPU;
        reason = io_step_cycle(state);
        if (reason != C02EMU_CYCLE_STEPPED) {
            return reason;
        }
    }
    
    return C02EMU_CYCLE_STEPPED;
}


C02EmuReturnReason c02emuRun(C02EmuState *state) {
    C02EmuReturnReason reason;
    
    for (;;) {
        
        if (state->phase == C02EMU_PHASE_CPU) {
            state->phase = C02EMU_PHASE_IO;
            reason = cpu_step_cycle(state);
            if (reason != C02EMU_CYCLE_STEPPED) {
                return reason;
            }
        }
        
        if (state->phase == C02EMU_PHASE_IO) {
            state->phase = C02EMU_PHASE_CPU;
            reason = io_step_cycle(state);
            if (reason != C02EMU_CYCLE_STEPPED) {
                return reason;
            }
        }
    }
}


const C02EmuOutput c02emuGetOutput(C02EmuState *state) {
    C02EmuOutput output;
    output.display.mode = state->io.display.mode;
    output.display.data = &state->mem.ram[state->io.display.base];
    return output;
}


#include "c02emu_util.c"
