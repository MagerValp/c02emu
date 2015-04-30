//
//  Disassembler.swift
//  c02emu
//
//  Created by Pelle on 2015-01-16.
//  Copyright (c) 2015 Per Olofsson. All rights reserved.
//

import Cocoa


protocol DisassemblerDelegate {
    func readMemory(addr: UInt16) -> UInt8
}


class Disassembler: NSObject {
    
    var delegate: DisassemblerDelegate
    
    enum AddrMode {
        case ABS
        case ABX
        case ABY
        case IAX
        case IMM
        case IMP
        case IND
        case IZP
        case IZX
        case IZY
        case REL
        case ZP
        case ZPR
        case ZPX
        case ZPY
    }
    
    let addrModes: [AddrMode] = [
        .IMP, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZP,  .ZPX, .ZPX, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABS, .ABX, .ABX, .ZPR,
        .ABS, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPX, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABX, .ABX, .ABX, .ZPR,
        .IMP, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPX, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABS, .ABX, .ABX, .ZPR,
        .IMP, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .IND, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPX, .ZP,
        .IMP, .ABY, .IMP, .IMP, .IAX, .ABX, .ABX, .ZPR,
        .REL, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPY, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABS, .ABX, .ABX, .ZPR,
        .IMM, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPY, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABX, .ABX, .ABY, .ZPR,
        .IMM, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPX, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABS, .ABX, .ABX, .ZPR,
        .IMM, .IZX, .IMM, .IMP, .ZP,  .ZP,  .ZP,  .ZP,
        .IMP, .IMM, .IMP, .IMP, .ABS, .ABS, .ABS, .ZPR,
        .REL, .IZY, .IZP, .IMP, .ZPX, .ZPX, .ZPX, .ZP,
        .IMP, .ABY, .IMP, .IMP, .ABS, .ABX, .ABX, .ZPR,
    ]
    
    let opCodes = [
        "brk", "ora", "nop", "nop", "tsb", "ora", "asl", "rmb0",
        "php", "ora", "asl", "nop", "tsb", "ora", "asl", "bbr0",
        "bpl", "ora", "ora", "nop", "trb", "ora", "asl", "rmb1",
        "clc", "ora", "inc", "nop", "trb", "ora", "asl", "bbr1",
        "jsr", "and", "nop", "nop", "bit", "and", "rol", "rmb2",
        "plp", "and", "rol", "nop", "bit", "and", "rol", "bbr2",
        "bmi", "and", "and", "nop", "bit", "and", "rol", "rmb3",
        "sec", "and", "dec", "nop", "bit", "and", "rol", "bbr3",
        "rti", "eor", "nop", "nop", "nop", "eor", "lsr", "rmb4",
        "pha", "eor", "lsr", "nop", "jmp", "eor", "lsr", "bbr4",
        "bvc", "eor", "eor", "nop", "nop", "eor", "lsr", "rmb5",
        "cli", "eor", "phy", "nop", "nop", "eor", "lsr", "bbr5",
        "rts", "adc", "nop", "nop", "stz", "adc", "ror", "rmb6",
        "pla", "adc", "ror", "nop", "jmp", "adc", "ror", "bbr6",
        "bvs", "adc", "adc", "nop", "stz", "adc", "ror", "rmb7",
        "sei", "adc", "ply", "nop", "jmp", "adc", "ror", "bbr7",
        "bra", "sta", "nop", "nop", "sty", "sta", "stx", "smb0",
        "dey", "bit", "txa", "nop", "sty", "sta", "stx", "bbs0",
        "bcc", "sta", "sta", "nop", "sty", "sta", "stx", "smb1",
        "tya", "sta", "txs", "nop", "stz", "sta", "stz", "bbs1",
        "ldy", "lda", "ldx", "nop", "ldy", "lda", "ldx", "smb2",
        "tay", "lda", "tax", "nop", "ldy", "lda", "ldx", "bbs2",
        "bcs", "lda", "lda", "nop", "ldy", "lda", "ldx", "smb3",
        "clv", "lda", "tsx", "nop", "ldy", "lda", "ldx", "bbs3",
        "cpy", "cmp", "nop", "nop", "cpy", "cmp", "dec", "smb4",
        "iny", "cmp", "dex", "wai", "cpy", "cmp", "dec", "bbs4",
        "bne", "cmp", "cmp", "nop", "nop", "cmp", "dec", "smb5",
        "cld", "cmp", "phx", "stp", "nop", "cmp", "dec", "bbs5",
        "cpx", "sbc", "nop", "nop", "cpx", "sbc", "inc", "smb6",
        "inx", "sbc", "nop", "nop", "cpx", "sbc", "inc", "bbs6",
        "beq", "sbc", "sbc", "nop", "nop", "sbc", "inc", "smb7",
        "sed", "sbc", "plx", "nop", "nop", "sbc", "inc", "bbs7",
    ]
    
    let modePrefix: [AddrMode:String] = [
        .ABS: "$",
        .ABX: "$",
        .ABY: "$",
        .IAX: "($",
        .IMM: "#$",
        .IMP: "",
        .IND: "($",
        .IZP: "($",
        .IZX: "($",
        .IZY: "($",
        .REL: "$",
        .ZP: "$",
        .ZPR: "$",
        .ZPX: "$",
        .ZPY: "$",
    ]
    let modeSuffix: [AddrMode:String] = [
        .ABS: "",
        .ABX: ",X",
        .ABY: ",Y",
        .IAX: ",X)",
        .IMM: "",
        .IMP: "",
        .IND: ")",
        .IZP: ")",
        .IZX: ",X)",
        .IZY: "),y",
        .REL: "",
        .ZP: "",
        .ZPR: "",
        .ZPX: ",X",
        .ZPY: ",Y",
    ]
    
    enum AddrFormat {
        case Word
        case Byte
        case Relative
        case ZPRelative
        case None
    }
    
    let opFormat: [AddrMode:AddrFormat] = [
        .ABS: .Word,
        .ABX: .Word,
        .ABY: .Word,
        .IAX: .Word,
        .IMM: .Byte,
        .IMP: .None,
        .IND: .Word,
        .IZP: .Byte,
        .IZX: .Byte,
        .IZY: .Byte,
        .REL: .Relative,
        .ZP: .Byte,
        .ZPR: .ZPRelative,
        .ZPX: .Byte,
        .ZPY: .Byte,
    ]
    
    var pc: UInt16 = 0
    
    init(delegate: DisassemblerDelegate) {
        self.delegate = delegate
    }
    
    func disassemble(addr: UInt16) -> String {
        pc = addr
        return disassemble()
    }
    
    func disassemble() -> String {
        var bytes = [UInt8]()
        var byte: UInt8
        var word: UInt16
        var output: String = NSString(format: "%04x   ", pc & 0xffff)
        
        byte = readIncPC()
        bytes.append(byte)
        output += NSString(format: "%02x ", byte)
        
        let code = opCodes[Int(byte)]
        let mode = addrModes[Int(byte)]
        let format = opFormat[mode]!
        
        var operand: String
        
        switch format {
        
        case .Byte:
            byte = readIncPC()
            bytes.append(byte)
            output += NSString(format: "%02x    ", byte)
            operand = NSString(format: "%02x", byte)
        
        case .Word:
            byte = readIncPC()
            bytes.append(byte)
            output += NSString(format: "%02x ", byte)
            word = UInt16(byte)
            
            byte = readIncPC()
            bytes.append(byte)
            output += NSString(format: "%02x ", byte)
            word = word | (UInt16(byte) << 8)
            
            operand = NSString(format: "%04x", word)
        
        case .Relative:
            byte = readIncPC()
            bytes.append(byte)
            output += NSString(format: "%02x    ", byte)
            word = UInt16((Int(pc) + Int(unsafeBitCast(byte, Int8.self))) & 0xffff)
            operand = NSString(format: "%04x", word)
            
        case .ZPRelative:
            byte = readIncPC()
            bytes.append(byte)
            output += NSString(format: "%02x ", byte)
            operand = NSString(format: "%02x", byte)
            
            byte = readIncPC()
            bytes.append(byte)
            output += NSString(format: "%02x ", byte)
            word = UInt16((Int(pc) + Int(unsafeBitCast(byte, Int8.self))) & 0xffff)
            operand = NSString(format: "%@,$%04x", operand, word)

        case .None:
            output += "      "
            operand = ""
        }
        
        return output + "  " + code + " " + modePrefix[mode]! + operand + modeSuffix[mode]!

    }
    
    func readIncPC() -> UInt8 {
        var byte = delegate.readMemory(UInt16(pc & 0xffff))
        pc = pc &+ 1
        return byte
    }
    
}
