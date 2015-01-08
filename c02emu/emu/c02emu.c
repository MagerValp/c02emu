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



#pragma mark • Declarations


typedef uint32_t LongAddr;

#define flag_c 0x01
#define flag_z 0x02
#define flag_i 0x04
#define flag_d 0x08
#define flag_b 0x10
#define flag_1 0x20
#define flag_v 0x40
#define flag_n 0x80

struct _c02EmuState {
    struct _state_cpu {
        Byte a, x, y, status, stack;
        Addr pc;
    } cpu;
    struct _state_mem {
        Byte ram[256 * 4096];
        Byte rom[4096];
    } mem;
    struct _io {
        struct _state_io_mmu {
            Byte page[16];
        } mmu;
        struct _state_io_display {
            Byte page;
            Byte ram[256 * 256];
        } display;
    } io;
};



#pragma mark • Private function prototypes


static LongAddr mmu_addr(C02EmuState *state, Addr addr);
static Byte raw_mem_read(C02EmuState *state, Addr addr);
static void raw_mem_write(C02EmuState *state, Addr addr, Byte byte);
static Byte raw_read_io(C02EmuState *state, Addr addr);
static void raw_write_io(C02EmuState *state, Addr addr, Byte byte);

static Byte raw_io_mmu_read(C02EmuState *state, Addr addr);
static void raw_io_mmu_write(C02EmuState *state, Addr addr, Byte byte);

static Addr display_addr(C02EmuState *state, Addr addr);
static Byte raw_io_display_read(C02EmuState *state, Addr addr);
static void raw_io_display_write(C02EmuState *state, Addr addr, Byte byte);



#pragma mark • Public functions


C02EmuState *c02emuCreate(void) {
    C02EmuState *state = malloc(sizeof(C02EmuState));
    if (state == NULL) {
        return NULL;
    }
    
    state->cpu.a = 0x00;
    state->cpu.x = 0x00;
    state->cpu.y = 0x00;
    state->cpu.status = flag_1;
    state->cpu.stack = 0xff;
    state->cpu.pc = 0x0000;
    
    memset(state->mem.ram, 0x00, sizeof(state->mem.ram));
    memset(state->mem.rom, 0xcb, sizeof(state->mem.rom));
    
    memset(state->io.display.ram, 0xff, sizeof(state->io.display.ram));
    state->io.display.page = 0x00;
    
    c02emuReset(state);
    
    return state;
}


void c02emuDestroy(C02EmuState *state) {
    free(state);
}


void c02emuLoadROM(C02EmuState *state, Byte *data, size_t size) {
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
    state->cpu.pc = raw_mem_read(state, 0xfffc) | (raw_mem_read(state, 0xfffd) << 8);
    state->cpu.status |= flag_i;
}


C02EmuReturnReason c02emuRun(C02EmuState *state) {
    return C02EMU_FRAME_READY;
}


const C02EmuOutput c02emuGetOutput(C02EmuState *state) {
    C02EmuOutput output;
    output.display.mode = C02EMU_DISPLAY_MODE_TEXT_80X50;
    output.display.data = state->io.display.ram;
    return output;
}


#pragma mark • Private functions


// Memory access and address decoding.


static LongAddr mmu_addr(C02EmuState *state, Addr addr) {
    unsigned int sourcePage = addr >> 12;
    Byte mmuPage = state->io.mmu.page[sourcePage];
    return (mmuPage << 12) | (addr & 0x0fff);
}


static Byte raw_mem_read(C02EmuState *state, Addr addr) {
    unsigned int region = addr & 0xf000;
    
    if (region == 0xe000 && state->io.mmu.page[0x0e] == 0xfe) {
        // Reads from $exxx access I/O if MMU page is $fe.
        return raw_read_io(state, addr);
    
    } else if (region == 0xf000 && state->io.mmu.page[0x0f] == 0xff) {
        // Reads from $fxxx access ROM if MMU page is $ff.
        return state->mem.rom[addr & 0x0fff];
    
    } else {
        return state->mem.ram[mmu_addr(state, addr)];
    }
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static void raw_mem_write(C02EmuState *state, Addr addr, Byte byte) {
#pragma clang diagnostic pop
    unsigned int region = addr & 0xf000;
    
    if (region == 0xf000 || (region == 0xe000 && state->io.mmu.page[0x0e] == 0xfe)) {
        // Writes to $fxxx always go to I/O.
        // Writes to $exxx go to I/O if MMU page is $fe.
        raw_write_io(state, addr, byte);
        return;
        
    } else {
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
