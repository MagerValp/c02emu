//
//  dis65c02.h
//  c02emu
//
//  Created by Per Olofsson on 2015-01-23.
//  Copyright (c) 2015 Per Olofsson. All rights reserved.
//

#ifndef __c02emu__dis65c02__
#define __c02emu__dis65c02__


#include <stdint.h>


/// mem_read callback prototype.
typedef uint8_t (*Dis65C02MemReader)(void *context, uint16_t addr);

/// Disassemble a 65C02 instruction at addr into buffer.
///
/// @param buffer       A character buffer to hold the output.
/// @param size         The size of the output buffer, in bytes.
/// @param addr         The memory address to disassemble.
/// @param mem_read     Callback function that returns memory for the specified address.
/// @param context      Passed to the mem_read callback.
void disassemble(char *buffer, size_t size, uint16_t addr, Dis65C02MemReader mem_read, void *context);


#endif /* defined(__c02emu__dis65c02__) */
