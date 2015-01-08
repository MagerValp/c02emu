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


typedef unsigned int LongAddr;

#define flag_c 0x01
#define flag_z 0x02
#define flag_i 0x04
#define flag_d 0x08
#define flag_b 0x10
#define flag_1 0x20
#define flag_v 0x40
#define flag_n 0x80



#pragma mark • Private function prototypes


static LongAddr mmu_addr(C02EmuState *state, Addr addr);
static Byte raw_mem_read(C02EmuState *state, Addr addr);
static void raw_mem_write(C02EmuState *state, Addr addr, Byte byte);
static Byte raw_read_io(C02EmuState *state, Addr addr);
static void raw_write_io(C02EmuState *state, Addr addr, Byte byte);

static Byte raw_io_mmu_read(C02EmuState *state, Addr addr);
static void raw_io_mmu_write(C02EmuState *state, Addr addr, Byte byte);



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


C02ReturnReason c02emuRun(C02EmuState *state) {
    return C02EMU_FRAME_READY;
}



#pragma mark • Private functions


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
    switch (addr & 0xf000) {
        case 0xe000:
        case 0xf000:
            raw_write_io(state, addr, byte);
            return;
            
        default:
            state->mem.ram[mmu_addr(state, addr)] = byte;
            return;
    }
}


static Byte raw_read_io(C02EmuState *state, Addr addr) {
    switch (addr & 0x0f00) {
        case 0x0000:
            return raw_io_mmu_read(state, addr);
            
        default:
            return 0xff;
    }
}


static void raw_write_io(C02EmuState *state, Addr addr, Byte byte) {
    switch (addr & 0x0f00) {
        case 0x0000:
            raw_io_mmu_write(state, addr, byte);
            return;
            
        default:
            return;
    }
}


static Byte raw_io_mmu_read(C02EmuState *state, Addr addr) {
    return state->io.mmu.page[addr & 0x000f];
}


static void raw_io_mmu_write(C02EmuState *state, Addr addr, Byte byte) {
    state->io.mmu.page[addr & 0x000f] = byte;
}
