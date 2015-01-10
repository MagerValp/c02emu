//
//  c02emu_private.h
//  c02emu
//
//  Created by Pelle on 2015-01-09.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

#ifndef __c02emu__c02emu_private__
#define __c02emu__c02emu_private__


#include <stdbool.h>
#include "c02emu.h"
#include "c02emu_uops.h"


typedef uint32_t LongAddr;

#define flag_c 0x01
#define flag_z 0x02
#define flag_i 0x04
#define flag_d 0x08
#define flag_b 0x10
#define flag_1 0x20
#define flag_v 0x40
#define flag_n 0x80

#define cycles_per_frame(FRAME_CTR) ((FRAME_CTR % 3) == 0 ? 133334 : 133333)

typedef enum {
    C02EMU_OP_CYCLE_1=0,    // Cycle 1 value is 0, and so on, to correctly index op table.
    C02EMU_OP_CYCLE_2,
    C02EMU_OP_CYCLE_3,
    C02EMU_OP_CYCLE_4,
    C02EMU_OP_CYCLE_5,
    C02EMU_OP_CYCLE_6,
    C02EMU_OP_CYCLE_7,
    C02EMU_OP_DONE,
    C02EMU_OP_STOPPED,
    C02EMU_OP_WAITING,
} C02EmuOpCycle;


#ifdef __LITTLE_ENDIAN__
#define BYTE_LH Byte l, h
#else
#ifdef __BIG_ENDIAN__
#define BYTE_LH Byte h, l;
#else
#error Endianness not defined.
#endif
#endif

struct _c02EmuState {
    struct {
        Byte a, x, y, status, stack;
        Addr pc;
        struct {
            Byte opcode;
            C02EmuUop *uop_list;
            C02EmuOpCycle cycle;
            bool stop_notified;
            bool address_fixup;
            bool decimal_fixup;
            Byte alu;
            union {
                Addr w;
                struct {
                    BYTE_LH;
                } b;
            } ad;
            union {
                Addr w;
                struct {
                    BYTE_LH;
                } b;
            } ba;
        } op;
    } cpu;
    struct {
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
    
    uint64_t cycle_counter;
    uint64_t frame_counter;
    uint64_t vbl_counter;
};


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


#endif /* defined(__c02emu__c02emu_private__) */
