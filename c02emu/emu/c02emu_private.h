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

#define C02EMU_CYCLES_PER_LINE 254
#define C02EMU_LINES_PER_FRAME 525

#define cycles_per_frame(FRAME_CTR) ((FRAME_CTR % 3) == 0 ? 133334 : 133333)

typedef enum {
    C02EMU_PHASE_CPU,
    C02EMU_PHASE_IO,
} C02EmuPhase;

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
            bool irq_active;
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
        Byte ram[128 * 4096];   // 512 kB RAM at $00000-$7ffff
        Byte rom[4096];         // 256 kB ROM at $c0000-$fffff
    } mem;
    struct {
        struct {
            Byte page[16];
        } mmu;
        struct {
            C02EmuDisplayMode mode;
            unsigned int base;
        } display;
    } io;
    
    C02EmuPhase phase;
    
    unsigned int cycle_ctr;
    unsigned int line_ctr;
    unsigned int frame_ctr;
    
    struct {
        bool trace_cpu;
        bool trace_ram;
    } monitor;
};


static C02EmuReturnReason cpu_step_cycle(C02EmuState *state);
static C02EmuReturnReason io_step_cycle(C02EmuState *state);

static LongAddr mmu_addr(C02EmuState *state, Addr addr);
static Byte raw_mem_read(C02EmuState *state, Addr addr);
static void raw_mem_write(C02EmuState *state, Addr addr, Byte byte);
static Byte io_read(C02EmuState *state, Addr addr);
static void io_write(C02EmuState *state, Addr addr, Byte byte);

static Byte io_mmu_read(C02EmuState *state, Addr addr);
static void io_mmu_write(C02EmuState *state, Addr addr, Byte byte);

static Byte io_display_read(C02EmuState *state, Addr addr);
static void io_display_write(C02EmuState *state, Addr addr, Byte byte);

static Byte io_debug_read(C02EmuState *state, Addr addr);
static void io_debug_write(C02EmuState *state, Addr addr, Byte byte);


#endif /* defined(__c02emu__c02emu_private__) */
