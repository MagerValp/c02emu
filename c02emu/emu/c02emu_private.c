//
//  c02emu_private.c
//  c02emu
//
//  Created by Pelle on 2015-01-09.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

#ifndef __c02emu__c02emu_private_c__
#define __c02emu__c02emu_private_c__


#include "c02emu_private.h"
#include <stdio.h>


// Memory access and address decoding.


static LongAddr mmu_addr(C02EmuState *state, Addr addr) {
    unsigned int sourcePage = addr >> 12;
    Byte mmuPage = state->io.mmu.page[sourcePage];
    return (mmuPage << 12) | (addr & 0x0fff);
}


static Byte raw_mem_read(C02EmuState *state, Addr addr) {
    Byte byte;
    unsigned int region = addr & 0xf000;
    
    if (region == 0xe000 && state->io.mmu.page[0x0e] == 0xfe) {
        // Reads from $exxx access I/O if MMU page is $fe.
        byte = raw_read_io(state, addr);
        if (state->monitor.trace_ram) {
            fprintf(stderr, "I/O %04x R %02x\n", addr, byte);
        }
        
    } else if (region == 0xf000 && state->io.mmu.page[0x0f] == 0xff) {
        // Reads from $fxxx access ROM if MMU page is $ff.
        byte = state->mem.rom[addr & 0x0fff];
        if (state->monitor.trace_ram) {
            fprintf(stderr, "ROM %04x R %02x\n", addr, byte);
        }
        
    } else {
        byte = state->mem.ram[mmu_addr(state, addr)];
        if (state->monitor.trace_ram) {
            fprintf(stderr, "RAM %04x R %02x\n", addr, byte);
        }
    }
    
    return byte;
}


static void raw_mem_write(C02EmuState *state, Addr addr, Byte byte) {
    unsigned int region = addr & 0xf000;
    
    if (region == 0xf000 || (region == 0xe000 && state->io.mmu.page[0x0e] == 0xfe)) {
        if (state->monitor.trace_ram) {
            fprintf(stderr, "I/O %04x W %02x\n", addr, byte);
        }
        // Writes to $fxxx always go to I/O.
        // Writes to $exxx go to I/O if MMU page is $fe.
        raw_write_io(state, addr, byte);
        return;
        
    } else {
        if (state->monitor.trace_ram) {
            fprintf(stderr, "RAM %04x W %02x\n", addr, byte);
        }
        state->mem.ram[mmu_addr(state, addr)] = byte;
        return;
    }
}


// I/O access.


static Byte raw_read_io(C02EmuState *state, Addr addr) {
    switch (addr & 0x0f00) {
        case 0x0000:
            return raw_io_mmu_read(state, addr);
            
        case 0x0200:
        case 0x0300:
            return raw_io_display_read(state, addr);
            
        case 0x0f00:
            return raw_io_debug_read(state, addr);
            
        default:
            return 0xff;
    }
}


static void raw_write_io(C02EmuState *state, Addr addr, Byte byte) {
    switch (addr & 0x0f00) {
        case 0x0000:
            raw_io_mmu_write(state, addr, byte);
            return;
            
        case 0x0200:
        case 0x0300:
            raw_io_display_write(state, addr, byte);
            return;
            
        case 0x0f00:
            raw_io_debug_write(state, addr, byte);
            return;
        
        default:
            return;
    }
}


// MMU.


static Byte raw_io_mmu_read(C02EmuState *state, Addr addr) {
    return state->io.mmu.page[addr & 0x000f];
}


static void raw_io_mmu_write(C02EmuState *state, Addr addr, Byte byte) {
    state->io.mmu.page[addr & 0x000f] = byte;
}


// Display.


static Addr display_addr(C02EmuState *state, Addr addr) {
    addr &= 0x00ff;
    addr |= state->io.display.page << 8;
    addr &= sizeof(state->io.display.ram) - 1;
    return addr;
}


static Byte raw_io_display_read(C02EmuState *state, Addr addr) {
    if (addr & 0x0100) {
        return state->io.display.page;
    } else {
        return state->io.display.ram[display_addr(state, addr)];
    }
}


static void raw_io_display_write(C02EmuState *state, Addr addr, Byte byte) {
    if (addr & 0x0100) {
        state->io.display.page = byte;
    } else {
        state->io.display.ram[display_addr(state, addr)] = byte;
    }
}


// Debug.


#include <stdio.h>

static Byte raw_io_debug_read(C02EmuState *state, Addr addr) {
    return 0;
}


static void raw_io_debug_write(C02EmuState *state, Addr addr, Byte byte) {
    fputc(byte, stderr);
}


#endif
