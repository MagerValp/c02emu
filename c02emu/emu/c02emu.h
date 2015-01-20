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

/// Opaque state structure.
typedef struct _c02EmuState C02EmuState;

/// CPU state.
typedef enum {
    C02EMU_OP_CYCLE_1=0,    // Cycle 1 value is 0, and so on, to correctly index op table.
    C02EMU_OP_CYCLE_2,
    C02EMU_OP_CYCLE_3,
    C02EMU_OP_CYCLE_4,
    C02EMU_OP_CYCLE_5,
    C02EMU_OP_CYCLE_6,
    C02EMU_OP_CYCLE_7,
    C02EMU_OP_FETCH,
    C02EMU_OP_STOPPED,
    C02EMU_OP_WAITING,
} C02EmuOpCycle;

/// Display modes.
typedef enum {
    C02EMU_DISPLAY_MODE_TEXT_80X50=0
} C02EmuDisplayMode;

/// Emulator output data.
typedef struct {
    struct _output_display {
        C02EmuDisplayMode mode;
        Byte *data;
    } display;
} C02EmuOutput;

/// Create emulator state and allocate all needed resources.
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
void c02emuLoadROM(C02EmuState *state, const void *data, size_t size);

/// Reset emulated machine.
///
/// @param state    Emulator state.
void c02emuReset(C02EmuState *state);

/// The reasons that c02emuRun may return.
typedef enum {
    C02EMU_FRAME_READY=1,
    C02EMU_CPU_STOPPED,
    C02EMU_CYCLE_STEPPED,
} C02EmuReturnReason;

/// Execute until a single cycle has passed.
///
/// May return early, check return reason.
///
/// @param state    Emulator state.
/// @return The reason that the emulator stopped.
C02EmuReturnReason c02emuStepCycle(C02EmuState *state);

/// Execute until a stopping condition occurs.
///
/// Before it can run a state must be created, a ROM image must be loaded, and reset must be called.
///
/// @param state    Emulator state.
/// @return The reason that the emulator stopped.
C02EmuReturnReason c02emuRun(C02EmuState *state);

/// Access emulator output.
///
/// @param state    Emulator state.
/// @return Data required for rendering the display.
const C02EmuOutput c02emuGetOutput(C02EmuState *state);

#endif /* defined(__c02emu__c02emu__) */
