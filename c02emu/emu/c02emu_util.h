//
//  c02emu_util.h
//  c02emu
//
//  Created by Pelle on 2015-01-10.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

#ifndef __c02emu__c02emu_util__
#define __c02emu__c02emu_util__


#include "c02emu.h"


typedef struct {
    Byte a, x, y, status, stack;
    Addr pc;
} C02EmuCPURegs;

typedef struct {
    Byte ir;
    C02EmuOpCycle op_state;
} C02EmuCPUState;

typedef struct {
    Byte _dummy;    // WTH is up with Swift here?
    Byte page[16];
} C02EmuMMUState;

typedef struct {
    unsigned int cycle_ctr;
    unsigned int line_ctr;
    unsigned int frame_ctr;
} C02EmuDisplayState;

C02EmuCPURegs c02emuCPURegs(C02EmuState *state);
C02EmuCPUState c02emuCPUState(C02EmuState *state);
C02EmuMMUState c02emuMMUState(C02EmuState *state);
C02EmuDisplayState c02emuDisplayState(C02EmuState *state);

Byte c02emuCPURead(C02EmuState *state, Addr addr);
void c02emuCPUWrite(C02EmuState *state, Addr addr, Byte byte);


#endif /* defined(__c02emu__c02emu_util__) */
