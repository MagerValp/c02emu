//
//  c02emu_private.c
//  c02emu
//
//  Created by Pelle on 2015-01-09.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

#ifndef __c02emu__c02emu_private_c__
#define __c02emu__c02emu_private_c__


#include <stdio.h>
#include "c02emu_private.h"
#include "c02emu_optable.h"


// Running and stepping.


static C02EmuReturnReason cpu_step_cycle(C02EmuState *state) {
    Byte op;
    
    if (state->cpu.op.cycle == C02EMU_OP_DONE) {
        
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
        
        if (state->cpu.op.irq_active) {
            op = 0;
            if (state->monitor.trace_cpu) {
                fprintf(stderr, "PC = %04x IRQ\n", state->cpu.pc);
            }
            state->cpu.op.uop_list = irq_op_table[OP_IRQ];
        } else {
            op = raw_mem_read(state, (state->cpu.pc)++);
            if (state->monitor.trace_cpu) {
                fprintf(stderr, "PC = %04x OP = %02x\n", (state->cpu.pc - 1) & 0xffff, op);
            }
            state->cpu.op.uop_list = op_table[op];
        }
        state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
        state->cpu.op.address_fixup = false;
        state->cpu.op.decimal_fixup = false;
        state->cpu.op.opcode = op;
        
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
        
        state->cpu.op.irq_active = false;
        if (!(state->cpu.status & flag_i)) {
            if (state->line_ctr == 0 /* && state->cycle_ctr == 0*/ ) {
                state->cpu.op.irq_active = true;
            }
        }
        // Evaluate NMIs here.
        
        state->cpu.op.uop_list[state->cpu.op.cycle](state);
        if (state->cpu.op.cycle < C02EMU_OP_DONE) {
            state->cpu.op.cycle += 1;
        }
    }
    
    return C02EMU_CYCLE_STEPPED;
}


static C02EmuReturnReason io_step_cycle(C02EmuState *state) {
    if (++state->cycle_ctr > C02EMU_CYCLES_PER_LINE) {
        state->cycle_ctr = 0;
        if (++state->line_ctr > C02EMU_LINES_PER_FRAME) {
            state->line_ctr = 0;
            state->frame_ctr += 1;
            return C02EMU_FRAME_READY;
        }
    }

    return C02EMU_CYCLE_STEPPED;
}


// Memory access and address decoding.


static LongAddr mmu_addr(C02EmuState *state, Addr addr) {
    unsigned int sourcePage = addr >> 12;
    Byte mmuPage = state->io.mmu.page[sourcePage];
    return (mmuPage << 12) | (addr & 0x0fff);
}


static Byte raw_mem_read(C02EmuState *state, Addr addr) {
    Byte byte;
    LongAddr la;
    
    if (addr <= 0x000f) {
        // 00-0f are hardwired to the MMU registers.
        byte = io_mmu_read(state, addr);
        if (state->monitor.trace_ram) {
            fprintf(stderr, "MMU %04x R %02x\n", addr, byte);
        }
    } else {
        // Others are translated by the MMU.
        la = mmu_addr(state, addr);
        if (la < 0x080000) {
            byte = state->mem.ram[la & (sizeof(state->mem.ram) - 1)];
            if (state->monitor.trace_ram) {
                fprintf(stderr, "RAM %04x R %02x\n", addr, byte);
            }
        } else if (la < 0x0c0000) {
            byte = io_read(state, addr);
            if (state->monitor.trace_ram) {
                fprintf(stderr, "I/O %04x R %02x\n", addr, byte);
            }
        } else {
            byte = state->mem.rom[la & (sizeof(state->mem.rom) - 1)];
            if (state->monitor.trace_ram) {
                fprintf(stderr, "ROM %04x R %02x\n", addr, byte);
            }
        }
    }
    
    return byte;
}


static void raw_mem_write(C02EmuState *state, Addr addr, Byte byte) {
    LongAddr la;
    
    if (addr <= 0x000f) {
        // 00-0f are hardwired to the MMU registers.
        io_mmu_write(state, addr, byte);
        if (state->monitor.trace_ram) {
            fprintf(stderr, "MMU %04x W %02x\n", addr, byte);
        }
    } else {
        // Others are translated by the MMU.
        la = mmu_addr(state, addr);
        if (la < 0x080000) {
            if (state->monitor.trace_ram) {
                fprintf(stderr, "RAM %04x W %02x\n", addr, byte);
            }
            state->mem.ram[la & (sizeof(state->mem.ram) - 1)] = byte;
        } else if (la < 0x0c0000) {
            if (state->monitor.trace_ram) {
                fprintf(stderr, "I/O %04x W %02x\n", addr, byte);
            }
            io_write(state, addr, byte);
        } else {
            if (state->monitor.trace_ram) {
                fprintf(stderr, "ROM %04x R %02x\n", addr, byte);
            }
            state->mem.rom[la & (sizeof(state->mem.rom) - 1)] = byte;
        }
    }
}


// I/O access.


static Byte io_read(C02EmuState *state, Addr addr) {
    switch (addr & 0x0f00) {
        case 0x0000:
            return io_display_read(state, addr);
            
        case 0x0f00:
            return io_debug_read(state, addr);
            
        default:
            return 0xff;
    }
}


static void io_write(C02EmuState *state, Addr addr, Byte byte) {
    switch (addr & 0x0f00) {
        case 0x0000:
            io_display_write(state, addr, byte);
            return;
            
        case 0x0f00:
            io_debug_write(state, addr, byte);
            return;
        
        default:
            return;
    }
}


// MMU.


static Byte io_mmu_read(C02EmuState *state, Addr addr) {
    return state->io.mmu.page[addr & 0x000f];
}


static void io_mmu_write(C02EmuState *state, Addr addr, Byte byte) {
    state->io.mmu.page[addr & 0x000f] = byte;
}


// Display.


static Byte io_display_read(C02EmuState *state, Addr addr) {
    switch (addr & 0x0f) {
        case 0x00:
            return state->io.display.base & 0xff;
            break;
            
        case 0x01:
            return (state->io.display.base >> 8) & 0xff;
            break;
            
        case 0x02:
            return (state->io.display.base >> 16) & 0x07;
            break;
        
        case 0x03:
            return (Byte)state->io.display.mode;
            break;
            
        default:
            return 0xff;
            break;
    }
}


static void io_display_write(C02EmuState *state, Addr addr, Byte byte) {
    switch (addr & 0x0f) {
        case 0x00:
            state->io.display.base = (state->io.display.base & 0x07ff00) | byte;
            break;
            
        case 0x01:
            state->io.display.base = (state->io.display.base & 0x0700ff) | (byte << 8);
            break;
            
        case 0x02:
            state->io.display.base = (state->io.display.base & 0x00ffff) | ((byte & 0x07) << 16);
            break;
            
        case 0x03:
            state->io.display.mode = byte & 0x03;
            break;
            
        default:
            break;
    }
}


// Debug.


#include <stdio.h>

static Byte io_debug_read(C02EmuState *state, Addr addr) {
    return 0;
}


static void io_debug_write(C02EmuState *state, Addr addr, Byte byte) {
    switch (addr & 0xff) {
        case 0x00:
            fputc(byte, stderr);
            break;
            
        case 0x02:
            fputs("\nDebug trap registers:\n", stderr);
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
            fputs("Stack:\n", stderr);
            fprintf(stderr, "01%02x", state->cpu.stack);
            for (Addr a = (0x0100 | state->cpu.stack) + 1; a < 0x200; a++) {
                fprintf(stderr, " %02x", raw_mem_read(state, a));
            }
            fputs("\n", stderr);
            fputs("ZP:\n", stderr);
            fputs("000c", stderr);
            for (Addr a = 0; a < 7; a++) {
                fprintf(stderr, " %02x", raw_mem_read(state, 0x000c + a));
            }
            fputs("\n", stderr);
            fputs("ABS:\n", stderr);
            fputs("0200", stderr);
            for (Addr a = 0; a < 8; a++) {
                fprintf(stderr, " %02x", raw_mem_read(state, 0x0200 + a));
            }
            fputs("\n", stderr);
            break;
            
        default:
            break;
    }
}


#endif
