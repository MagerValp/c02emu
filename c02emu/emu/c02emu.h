//
//  c02emu.h
//  c02emu
//
//  Created by Pelle on 2015-01-07.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

#ifndef __c02emu__c02emu__
#define __c02emu__c02emu__

#include <stdint.h>

typedef uint8_t Byte;
typedef uint16_t Addr;

typedef struct {
    struct _cpu {
        Byte a, x, y, status, stack;
        Addr pc;
    } cpu;
    struct _mem {
        Byte ram[256 * 4096];
        Byte rom[4096];
    } mem;
    struct _io {
        struct _mmu {
            Byte page[16];
        } mmu;
    } io;
} C02EmuState;


/// Create an emulator state struct and allocate all needed resources.
///
/// @return Emulator state struct, or NULL.
C02EmuState *c02emuCreate(void);

/// Destroy state and release all allocated resources.
///
/// @param state    Emulator state.
void c02emuDestroy(C02EmuState *state);

/// Load ROM image.
///
/// @param state    Emulator state.
/// @param data     ROM image.
/// @param size     Size of ROM image in bytes.
void c02emuLoadROM(C02EmuState *state, Byte *data, size_t size);

/// Reset emulated machine.
///
/// @param state    Emulator state.
void c02emuReset(C02EmuState *state);

/// The reasons that c02emuRun may return.
typedef enum {
    C02EMU_FRAME_READY=1
} C02ReturnReason;

/// Execute until a stopping condition occurs.
///
/// Before it can run a state must be created, a ROM image must be loaded, and reset must be called.
///
/// @param state    Emulator state.
/// @return The reason that the emulator stopped.
C02ReturnReason c02emuRun(C02EmuState *state);


#endif /* defined(__c02emu__c02emu__) */
