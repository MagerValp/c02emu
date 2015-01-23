//
//  dis65c02.c
//  c02emu
//
//  Created by Per Olofsson on 2015-01-23.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//


#include <stdio.h>
#include <assert.h>
#include "dis65c02.h"


typedef enum {
    ABS,
    ABX,
    ABY,
    IAX,
    IMM,
    IMP,
    IND,
    IZP,
    IZX,
    IZY,
    REL,
    ZP,
    ZPR,
    ZPX,
    ZPY
} AddrMode;

static AddrMode addr_mode[256] = {
    IMP, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZP,  ZPX, ZPX, ZP,
    IMP, ABY, IMP, IMP, ABS, ABX, ABX, ZPR,
    ABS, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPX, ZP,
    IMP, ABY, IMP, IMP, ABX, ABX, ABX, ZPR,
    IMP, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPX, ZP,
    IMP, ABY, IMP, IMP, ABS, ABX, ABX, ZPR,
    IMP, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, IND, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPX, ZP,
    IMP, ABY, IMP, IMP, IAX, ABX, ABX, ZPR,
    REL, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPY, ZP,
    IMP, ABY, IMP, IMP, ABS, ABX, ABX, ZPR,
    IMM, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPY, ZP,
    IMP, ABY, IMP, IMP, ABX, ABX, ABY, ZPR,
    IMM, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPX, ZP,
    IMP, ABY, IMP, IMP, ABS, ABX, ABX, ZPR,
    IMM, IZX, IMM, IMP, ZP,  ZP,  ZP,  ZP,
    IMP, IMM, IMP, IMP, ABS, ABS, ABS, ZPR,
    REL, IZY, IZP, IMP, ZPX, ZPX, ZPX, ZP,
    IMP, ABY, IMP, IMP, ABS, ABX, ABX, ZPR
};

static char *op_code[256] = {
    "BRK", "ORA", "NOP", "NOP", "TSB", "ORA", "ASL", "RMB0",
    "PHP", "ORA", "ASL", "NOP", "TSB", "ORA", "ASL", "BBR0",
    "BPL", "ORA", "ORA", "NOP", "TRB", "ORA", "ASL", "RMB1",
    "CLC", "ORA", "INC", "NOP", "TRB", "ORA", "ASL", "BBR1",
    "JSR", "AND", "NOP", "NOP", "BIT", "AND", "ROL", "RMB2",
    "PLP", "AND", "ROL", "NOP", "BIT", "AND", "ROL", "BBR2",
    "BMI", "AND", "AND", "NOP", "BIT", "AND", "ROL", "RMB3",
    "SEC", "AND", "DEC", "NOP", "BIT", "AND", "ROL", "BBR3",
    "RTI", "EOR", "NOP", "NOP", "NOP", "EOR", "LSR", "RMB4",
    "PHA", "EOR", "LSR", "NOP", "JMP", "EOR", "LSR", "BBR4",
    "BVC", "EOR", "EOR", "NOP", "NOP", "EOR", "LSR", "RMB5",
    "CLI", "EOR", "PHY", "NOP", "NOP", "EOR", "LSR", "BBR5",
    "RTS", "ADC", "NOP", "NOP", "STZ", "ADC", "ROR", "RMB6",
    "PLA", "ADC", "ROR", "NOP", "JMP", "ADC", "ROR", "BBR6",
    "BVS", "ADC", "ADC", "NOP", "STZ", "ADC", "ROR", "RMB7",
    "SEI", "ADC", "PLY", "NOP", "JMP", "ADC", "ROR", "BBR7",
    "BRA", "STA", "NOP", "NOP", "STY", "STA", "STX", "SMB0",
    "DEY", "BIT", "TXA", "NOP", "STY", "STA", "STX", "BBS0",
    "BCC", "STA", "STA", "NOP", "STY", "STA", "STX", "SMB1",
    "TYA", "STA", "TXS", "NOP", "STZ", "STA", "STZ", "BBS1",
    "LDY", "LDA", "LDX", "NOP", "LDY", "LDA", "LDX", "SMB2",
    "TAY", "LDA", "TAX", "NOP", "LDY", "LDA", "LDX", "BBS2",
    "BCS", "LDA", "LDA", "NOP", "LDY", "LDA", "LDX", "SMB3",
    "CLV", "LDA", "TSX", "NOP", "LDY", "LDA", "LDX", "BBS3",
    "CPY", "CMP", "NOP", "NOP", "CPY", "CMP", "DEC", "SMB4",
    "INY", "CMP", "DEX", "WAI", "CPY", "CMP", "DEC", "BBS4",
    "BNE", "CMP", "CMP", "NOP", "NOP", "CMP", "DEC", "SMB5",
    "CLD", "CMP", "PHX", "STP", "NOP", "CMP", "DEC", "BBS5",
    "CPX", "SBC", "NOP", "NOP", "CPX", "SBC", "INC", "SMB6",
    "INX", "SBC", "NOP", "NOP", "CPX", "SBC", "INC", "BBS6",
    "BEQ", "SBC", "SBC", "NOP", "NOP", "SBC", "INC", "SMB7",
    "SED", "SBC", "PLX", "NOP", "NOP", "SBC", "INC", "BBS7",
};

static char *mode_prefix[15] = {
    "$",
    "$",
    "$",
    "($",
    "#$",
    "",
    "($",
    "($",
    "($",
    "($",
    "$",
    "$",
    "$",
    "$",
    "$",
};

static char *mode_suffix[15] = {
    "",
    ",X",
    ",Y",
    ",X)",
    "",
    "",
    ")",
    ")",
    ",X)",
    "),y",
    "",
    "",
    "",
    ",X",
    ",Y",
};

typedef enum {
    WORD,
    BYTE,
    RELATIVE,
    ZPRELATIVE,
    IMPLIED
} AddrFormat;

static int byte_count[5] = {
    3,
    2,
    2,
    3,
    1
};

static AddrFormat op_format[15] = {
    WORD,
    WORD,
    WORD,
    WORD,
    BYTE,
    IMPLIED,
    WORD,
    BYTE,
    BYTE,
    BYTE,
    RELATIVE,
    BYTE,
    ZPRELATIVE,
    BYTE,
    BYTE,
};


void disassemble(char *buffer, size_t size, uint16_t addr, Dis65C02MemReader mem_read, void *context) {
    uint8_t bytes[3];
    int num_bytes;
    AddrMode mode;
    AddrFormat format;
    uint16_t rel_addr;
    
    bytes[0] = mem_read(context, addr++);
    num_bytes = 1;
    
    mode = addr_mode[bytes[0]];
    format = op_format[mode];
    
    while (num_bytes < byte_count[format]) {
        bytes[num_bytes++] = mem_read(context, addr++);
    }
    
    switch (format) {
        case BYTE:
            snprintf(buffer, size, "%04x  %02x %02x     %-4s %s%02x%s",
                     (addr - num_bytes) & 0xffff,
                     bytes[0],
                     bytes[1],
                     op_code[bytes[0]],
                     mode_prefix[mode],
                     bytes[1],
                     mode_suffix[mode]);
            break;
            
        case WORD:
            snprintf(buffer, size, "%04x  %02x %02x %02x  %-4s %s%02x%02x%s",
                     (addr - num_bytes) & 0xffff,
                     bytes[0],
                     bytes[1],
                     bytes[2],
                     op_code[bytes[0]],
                     mode_prefix[mode],
                     bytes[2],
                     bytes[1],
                     mode_suffix[mode]);
            break;
            
        case RELATIVE:
            rel_addr = (addr + (int8_t)bytes[1]) & 0xffff;
            snprintf(buffer, size, "%04x  %02x %02x     %-4s %s%04x%s",
                     (addr - num_bytes) & 0xffff,
                     bytes[0],
                     bytes[1],
                     op_code[bytes[0]],
                     mode_prefix[mode],
                     rel_addr,
                     mode_suffix[mode]);
            break;
            
        case ZPRELATIVE:
            rel_addr = (addr + (int8_t)bytes[1]) & 0xffff;
            snprintf(buffer, size, "%04x  %02x %02x %02x  %-4s %s%02x,$%04x%s",
                     (addr - num_bytes) & 0xffff,
                     bytes[0],
                     bytes[1],
                     bytes[2],
                     op_code[bytes[0]],
                     mode_prefix[mode],
                     bytes[1],
                     rel_addr,
                     mode_suffix[mode]);
            break;
            
        case IMPLIED:
            snprintf(buffer, size, "%04x  %02x        %s",
                     (addr - num_bytes) & 0xffff,
                     bytes[0],
                     op_code[bytes[0]]);
            break;
            
       default:
            assert(0);
            break;
    }
}