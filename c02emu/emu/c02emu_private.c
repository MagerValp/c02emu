//
//  c02emu_private.c
//  c02emu
//
//  Created by Pelle on 2015-01-09.
//  Copyright (c) 2015 Per Olofsson. All rights reserved.
//

#ifndef __c02emu__c02emu_private_c__
#define __c02emu__c02emu_private_c__


#include <stdio.h>
#include "dis65c02.h"
#include "c02emu_private.h"
#include "c02emu_optable.h"


// Running and stepping.


static void evaluate_irqs(C02EmuState *state) {
    bool nmi;
    
    // IRQ is masked by the I flag.
    state->cpu.op.irq_active = (state->cpu.status & flag_i) == 0 && (
        (state->io.display.irq_status & C02EMU_DISPLAY_IRQ_ACTIVE)
    );
    // NMI is edge triggered, so only active if it changed from the previous cycle.
    nmi = false;
    if (nmi && nmi != state->cpu.op.nmi_previous) {
        state->cpu.op.nmi_active = true;
    }
    state->cpu.op.nmi_previous = nmi;
}


static void cpu_step_cycle(C02EmuState *state) {
    Byte op;
    char disasm_buf[80];
    char trace_buf[80];
    
    if (state->cpu.op.cycle == C02EMU_OP_FETCH) {
        
        if (state->monitor.trace & C02EMU_TRACE_CPU) {
            sprintf(trace_buf, "A:%02x X:%02x Y:%02x S:%02x  %c%c1%c%c%c%c%c",
                    state->cpu.a,
                    state->cpu.x,
                    state->cpu.y,
                    state->cpu.stack,
                    (state->cpu.status & flag_n) ? 'N' : '.',
                    (state->cpu.status & flag_v) ? 'V' : '.',
                    (state->cpu.status & flag_b) ? 'B' : '.',
                    (state->cpu.status & flag_d) ? 'D' : '.',
                    (state->cpu.status & flag_i) ? 'I' : '.',
                    (state->cpu.status & flag_z) ? 'Z' : '.',
                    (state->cpu.status & flag_c) ? 'C' : '.');
        }
        
        state->cpu.op.address_fixup = false;
        state->cpu.op.decimal_fixup = false;
        
        if (state->cpu.op.nmi_active || state->cpu.op.irq_active) {
            op = 0;
            state->cpu.op.opcode = op;
            if (state->cpu.op.nmi_active) {
                if (state->monitor.trace & C02EMU_TRACE_CPU) {
                    fprintf(stderr, "%04x            NMI             %s\n", state->cpu.pc, trace_buf);
                }
                state->cpu.op.uop_list = irq_op_table[OP_NMI];
            } else if (state->cpu.op.irq_active) {
                if (state->monitor.trace & C02EMU_TRACE_CPU) {
                    fprintf(stderr, "%04x            IRQ             %s\n", state->cpu.pc, trace_buf);
                }
                state->cpu.op.uop_list = irq_op_table[OP_IRQ];
            }
            state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
            state->cpu.op.uop_list[state->cpu.op.cycle](state);
            if (state->cpu.op.cycle < C02EMU_OP_FETCH) {
                state->cpu.op.cycle += 1;
            }
        } else {
            op = cpu_read(state, (state->cpu.pc)++);
            state->cpu.op.opcode = op;
            if (state->monitor.trace & C02EMU_TRACE_CPU) {
                disassemble(disasm_buf, sizeof(disasm_buf), (state->cpu.pc - 1), (Dis65C02MemReader)cpu_read, state);
                fprintf(stderr, "%-30s  %s\n", disasm_buf, trace_buf);
            }
            state->cpu.op.uop_list = op_table[op];
            
            if (state->cpu.op.uop_list[0] == NULL) {
                evaluate_irqs(state);
                state->cpu.op.cycle = C02EMU_OP_FETCH;
            } else {
                state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
            }
        }
        
    } else if (state->cpu.op.cycle == C02EMU_OP_STOPPED) {
        
        //
        
    } else if (state->cpu.op.cycle == C02EMU_OP_WAITING) {
        
        cpu_read(state, state->cpu.pc);
        evaluate_irqs(state);
        if (state->cpu.op.irq_active || state->cpu.op.nmi_active) {
            if ((state->cpu.status & flag_i)) {
                // Continue at PC if I is set.
                state->cpu.op.cycle = C02EMU_OP_FETCH;
            } else {
                // Jump to vector.
                op = 0;
                if (state->monitor.trace & C02EMU_TRACE_CPU) {
                    fprintf(stderr, "PC = %04x %s\n", state->cpu.pc, state->cpu.op.nmi_active ? "NMI" : "IRQ");
                }
                state->cpu.op.uop_list = irq_op_table[OP_IRQ];
                state->cpu.op.cycle = C02EMU_OP_CYCLE_1;
                state->cpu.op.address_fixup = false;
                state->cpu.op.decimal_fixup = false;
                state->cpu.op.opcode = op;
            }
        }
        
    } else {
        
        evaluate_irqs(state);
        state->cpu.op.uop_list[state->cpu.op.cycle](state);
        if (state->cpu.op.cycle < C02EMU_OP_FETCH) {
            state->cpu.op.cycle += 1;
        }
    }
}


static void io_step_cycle(C02EmuState *state) {
    if (++state->cycle_ctr > C02EMU_CYCLES_PER_LINE) {
        state->cycle_ctr = 0;
        if (++state->line_ctr > C02EMU_LINES_PER_FRAME) {
            state->line_ctr = 0;
            state->frame_ctr += 1;
            if (state->io.display.irq_mask & C02EMU_DISPLAY_IRQ_VBL) {
                state->io.display.irq_status |= C02EMU_DISPLAY_IRQ_ACTIVE | C02EMU_DISPLAY_IRQ_VBL;
            }
        }
    }
}


// Memory access and address decoding.


static LongAddr mmu_addr(C02EmuState *state, Addr addr) {
    unsigned int sourcePage = addr >> 12;
    Byte mmuPage = state->io.mmu.page[sourcePage];
    return (mmuPage << 12) | (addr & 0x0fff);
}


static Byte cpu_read(C02EmuState *state, Addr addr) {
    Byte byte;
    LongAddr la;
    
    if (addr <= 0x000f) {
        // 00-0f are hardwired to the MMU registers.
        byte = io_mmu_read(state, addr);
        if (state->monitor.trace & C02EMU_TRACE_READ) {
            fprintf(stderr, "Read %04x > %02x (MMU)\n", addr, byte);
        }
    } else {
        // Others are translated by the MMU.
        la = mmu_addr(state, addr);
        if (la < 0x080000) {
            byte = state->mem.ram[la & (sizeof(state->mem.ram) - 1)];
            if (state->monitor.trace & C02EMU_TRACE_READ) {
                fprintf(stderr, "Read %04x > %02x (RAM)\n", addr, byte);
            }
        } else if (la < 0x0c0000) {
            byte = io_read(state, addr);
            if (state->monitor.trace & C02EMU_TRACE_READ) {
                fprintf(stderr, "Read %04x > %02x (I/O)\n", addr, byte);
            }
        } else {
            byte = state->mem.rom[la & (sizeof(state->mem.rom) - 1)];
            if (state->monitor.trace & C02EMU_TRACE_READ) {
                fprintf(stderr, "Read %04x > %02x (ROM)\n", addr, byte);
            }
        }
    }
    
    return byte;
}


static void cpu_write(C02EmuState *state, Addr addr, Byte byte) {
    LongAddr la;
    
    if (addr <= 0x000f) {
        // 00-0f are hardwired to the MMU registers.
        io_mmu_write(state, addr, byte);
        if (state->monitor.trace & C02EMU_TRACE_WRITE) {
            fprintf(stderr, "Write %04x < %02x (MMU)\n", addr, byte);
        }
    } else {
        // Others are translated by the MMU.
        la = mmu_addr(state, addr);
        if (la < 0x080000) {
            if (state->monitor.trace & C02EMU_TRACE_WRITE) {
                fprintf(stderr, "Write %04x < %02x (RAM)\n", addr, byte);
            }
            state->mem.ram[la & (sizeof(state->mem.ram) - 1)] = byte;
        } else if (la < 0x0c0000) {
            if (state->monitor.trace & C02EMU_TRACE_WRITE) {
                fprintf(stderr, "Write %04x < %02x (I/O)\n", addr, byte);
            }
            io_write(state, addr, byte);
        } else {
            if (state->monitor.trace & C02EMU_TRACE_WRITE) {
                fprintf(stderr, "Write %04x < %02x (ROM, ignored)\n", addr, byte);
            }
        }
    }
}


// I/O access.


static Byte io_read(C02EmuState *state, Addr addr) {
    switch (addr & 0x0f00) {
        case 0x0000:
            return io_display_read(state, addr);
            
        case 0x0800:
            return io_keyboard_read(state, addr);
            
        case 0x0f00:
            if (state->monitor.debug_output) {
                return io_debug_read(state, addr);
            }
            
        default:
            return 0xff;
    }
}


static void io_write(C02EmuState *state, Addr addr, Byte byte) {
    switch (addr & 0x0f00) {
        case 0x0000:
            io_display_write(state, addr, byte);
            return;
            
        case 0x0800:
            io_keyboard_write(state, addr, byte);
            return;
            
        case 0x0f00:
            if (state->monitor.debug_output) {
                io_debug_write(state, addr, byte);
            }
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
            
        case 0x04:
            return (Byte)state->io.display.irq_mask;
            break;
            
        case 0x05:
            return (Byte)state->io.display.irq_status;
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
            
        case 0x04:
            state->io.display.irq_mask = byte & 0x81;
            break;
            
        case 0x05:
            state->io.display.irq_status &= ~(byte & C02EMU_DISPLAY_IRQ_VBL);
            if ((state->io.display.irq_status & C02EMU_DISPLAY_IRQ_VBL) == 0) {
                state->io.display.irq_status = 0;
            }
            break;
            
        default:
            break;
    }
}


// Keyboard.


static Byte io_keyboard_read(C02EmuState *state, Addr addr) {
    Byte byte;
    
    switch (addr & 1) {
        case 0:
            byte = state->io.keyboard.queue[state->io.keyboard.index];
            if (state->io.keyboard.size) {
                state->io.keyboard.index = (state->io.keyboard.index + 1) & (sizeof(state->io.keyboard.queue) - 1);
                state->io.keyboard.size -= 1;
            }
            return byte;
            
        case 1:
            return state->io.keyboard.size;
            
        default:
            return 0xff;
    }
}


static void io_keyboard_write(C02EmuState *state, Addr addr, Byte byte) {
    return;
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
                    (state->cpu.pc - 3) & 0xffff,
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
                fprintf(stderr, " %02x", cpu_read(state, a));
            }
            fputs("\n", stderr);
            fputs("ZP:\n", stderr);
            fputs("0010", stderr);
            for (Addr a = 0; a < 7; a++) {
                fprintf(stderr, " %02x", cpu_read(state, 0x0010 + a));
            }
            fputs("\n", stderr);
            fputs("ABS:\n", stderr);
            fputs("0200", stderr);
            for (Addr a = 0; a < 8; a++) {
                fprintf(stderr, " %02x", cpu_read(state, 0x0200 + a));
            }
            fputs("\n", stderr);
            break;
            
        case 0x03:
            fprintf(stderr, "Running test %d\n", state->cpu.a);
            break;
            
        case 0x04:
            while ((byte = cpu_read(state, state->cpu.pc++)) != 0) {
                fputc(byte, stderr);
            }
            break;
            
        case 0x0b:
            state->monitor.trace = byte;
            break;
            
        case 0x0c:
            state->monitor.trace |= C02EMU_TRACE_CPU;
            break;
            
        case 0x0d:
            state->monitor.trace &= ~C02EMU_TRACE_CPU;
            break;
            
        case 0x0e:
            state->monitor.trace |= C02EMU_TRACE_READ | C02EMU_TRACE_WRITE;
            break;
            
        case 0x0f:
            state->monitor.trace &= ~(C02EMU_TRACE_READ | C02EMU_TRACE_WRITE);
            break;
            
        default:
            break;
    }
}


#endif
