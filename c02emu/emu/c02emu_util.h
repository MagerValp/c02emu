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


C02EmuCPURegs *c02emuCPURegs(C02EmuState *state);

Byte c02emuCPURead(C02EmuState *state, Addr addr);

void c02emuCPUWrite(C02EmuState *state, Addr addr, Byte byte);


#endif /* defined(__c02emu__c02emu_util__) */
