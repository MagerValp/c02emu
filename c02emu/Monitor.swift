//
//  Monitor.swift
//  c02emu
//
//  Created by Pelle on 2015-01-15.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa


protocol MonitorDelegate {
    func outputMessage(msg: String)
    func outputError(msg: String)
    func exitMonitor()
    func willExecuteCommand()
    func didExecuteCommand()
}


class Monitor: NSObject {
    
    enum StringParserState: String {
        case Base = "Base"
        case EscapedCharacter = "EscapedCharacter"
        case DoubleQuotedString = "DoubleQuotedString"
        case EscapedCharacterInQuotes = "EscapedCharacterInQuotes"
        case SingleQuotedString = "SingleQuotedString"
    }

    weak var emulator: EmulatorController!
    var delegate: MonitorDelegate!
    var disassembler: Disassembler
    
    init(emulator theEmulator: EmulatorController) {
        emulator = theEmulator
        disassembler = Disassembler(delegate: emulator)
    }
    
    func outputLine(line: String) {
        delegate.outputMessage(line + "\n")
    }
    
    func outputErrorLine(line: String) {
        delegate.outputError(line + "\n")
    }

    func parseCommand(cmdBuffer: String) -> [String]? {
        let chars = Array(cmdBuffer)
        var state = StringParserState.Base
        var i = 0
        var currentChar: Character
        var currentToken = ""
        var tokens = [String]()
        
        while i < chars.count {
            
            currentChar = chars[i++]
            
            if state == .EscapedCharacter {
                currentToken += String(currentChar)
                state = .Base
                
            } else if state == .EscapedCharacterInQuotes {
                currentToken += String(currentChar)
                state = .DoubleQuotedString
                
            } else if state == .Base {
                switch currentChar {
                case "\\":
                    state = .EscapedCharacter
                case "\"":
                    state = .DoubleQuotedString
                case "'":
                    state = .SingleQuotedString
                case " ", "\t", "\r", "\n":
                    if currentToken != "" {
                        tokens.append(currentToken)
                        currentToken = ""
                    }
                default:
                    currentToken = currentToken + String(currentChar)
                }
                
            } else if state == .DoubleQuotedString {
                switch currentChar {
                case "\\":
                    state = .EscapedCharacterInQuotes
                case "\"":
                    state = .Base
                default:
                    currentToken = currentToken + String(currentChar)
                }
                
            } else if state == .SingleQuotedString {
                switch currentChar {
                case "'":
                    state = .Base
                default:
                    currentToken = currentToken + String(currentChar)
                }
            }

        }
        if state != .Base {
            return nil
        }
        
        if currentToken != "" {
            tokens.append(currentToken)
            currentToken = ""
        }
        
        return tokens
    }
    
    func executeCommand(cmdBuffer: String) {
        delegate.willExecuteCommand()
        if let cmdTokens = parseCommand(cmdBuffer) {
            if cmdTokens.count == 0 {
                outputErrorLine("")
            }
            
            let args: [String]? = cmdTokens.count > 1 ? Array(cmdTokens[1 ..< cmdTokens.count]) : nil
            
            switch cmdTokens[0] {
                
            case "__ENTER_MONITOR":
                cmdEnterMonitor(args)
                
            case "d":
                cmdDisassemble(args)
            
            case "m":
                cmdShowMemory(args)
                
            case "mmu":
                cmdMMU(args)
                
            case "r":
                cmdShowRegs(args)
                
            case "sc":
                cmdStepCycle(args)
            
            case "si":
                cmdStepInstruction(args)
                
            case "x":
                delegate.exitMonitor()
                
            default:
                outputErrorLine("Unknown command (? for help)")
                
            }
        } else {
            outputErrorLine("Syntax error")
        }
        delegate.didExecuteCommand()
    }

    var output = [String]()
    
    func badArgs() {
        outputErrorLine("Bad args (? for help)")
    }
    
    let flag_c = 0x01
    let flag_z = 0x02
    let flag_i = 0x04
    let flag_d = 0x08
    let flag_b = 0x10
    let flag_1 = 0x20
    let flag_v = 0x40
    let flag_n = 0x80
    
    
    func cmdEnterMonitor(args: [String]?) {
        outputLine(NSString(format: "***BREAK at frame %d line %d cycle %d",
            emulator.state.display.frame,
            emulator.state.display.line,
            emulator.state.display.cycle))
    }
    
    
    func cmdShowMemory(args: [String]?) {
        var from: UInt16 = emulator.state.cpu.pc
        var to: UInt16 = emulator.state.cpu.pc &+ 255
        
        if let args = args {
            if args.count > 2 {
                outputErrorLine("Usage: m [start] [end]")
                return
            }
            if args.count >= 1 {
                if let addr = argAsUInt16(args[0]) {
                    from = addr
                    if args.count >= 2 {
                        if let addr = argAsUInt16(args[1]) {
                            to = addr
                        } else {
                            outputErrorLine("Expected address argument")
                            return
                        }
                    } else {
                        to = from &+ 255
                    }
                } else {
                    outputErrorLine("Expected address argument")
                    return
                }
            }
        }
        
        let bytes = to &- from
        var addr = from
        while addr &- from <= bytes {
            var output: String = NSString(format: "%04x  ", addr)
            var ascii = ""
            for i in 0..<16 {
                let byte = emulator.readMemory(addr)
                output += NSString(format: " %02x", byte)
                if byte >= 0x20 && byte < 0x7f {
                    ascii += String(UnicodeScalar(Int(byte)))
                } else {
                    ascii += "."
                }
                addr = addr &+ 1
            }
            outputLine(output + "   " + ascii)
        }
    }
    
    func cmdShowRegs(args: [String]?) {
        if args != nil {
            return badArgs()
        }
        
        outputLine("PC   A  X  Y  S  nv1bdizc  IR  CPU State    Line Cycle")
        let state = emulator.state
        let status = NSString(format: "%d%d1%d%d%d%d%d",
            (Int(state.cpu.status) & flag_n) >> 7,
            (Int(state.cpu.status) & flag_v) >> 6,
            (Int(state.cpu.status) & flag_b) >> 4,
            (Int(state.cpu.status) & flag_d) >> 3,
            (Int(state.cpu.status) & flag_i) >> 2,
            (Int(state.cpu.status) & flag_z) >> 1,
            (Int(state.cpu.status) & flag_c))
        state.cpu.state.description.withCString {
            cpuState in
            self.outputLine(NSString(format: "%04x %02x %02x %02x %02x %@  %02x  %-11s  %03d  %03d",
                state.cpu.pc,
                state.cpu.a,
                state.cpu.x,
                state.cpu.y,
                state.cpu.stack,
                status,
                state.cpu.ir,
                COpaquePointer(cpuState),
                state.display.line,
                state.display.cycle))
        }
    }
    
    func cmdStepCycle(args: [String]?) {
        emulator.step()
        cmdShowRegs(nil)
    }
    
    func cmdStepInstruction(args: [String]?) {
        emulator.step()
        for ;; {
            switch emulator.state.cpu.state {
            case .FetchingOp:
                cmdShowRegs(nil)
                outputLine(disassembler.disassemble(emulator.state.cpu.pc))
                return
            case .Stopped:
                cmdShowRegs(nil)
                return
            default:
                emulator.step()
            }
        }
    }
    
    func cmdDisassemble(args: [String]?) {
        var from: UInt16 = emulator.state.cpu.pc
        var to: UInt16 = emulator.state.cpu.pc &+ 32
        
        if let args = args {
            if args.count > 2 {
                outputErrorLine("Usage: d [start] [end]")
                return
            }
            if args.count >= 1 {
                if let addr = argAsUInt16(args[0]) {
                    from = addr
                    if args.count >= 2 {
                        if let addr = argAsUInt16(args[1]) {
                            to = addr
                        } else {
                            outputErrorLine("Expected address argument")
                            return
                        }
                    } else {
                        to = from &+ 255
                    }
                } else {
                    outputErrorLine("Expected address argument")
                    return
                }
            }
        }
        
        let bytes = to &- from
        outputLine(disassembler.disassemble(from))
        while disassembler.pc &- from < bytes {
            outputLine(disassembler.disassemble())
        }
    }
    
    func argAsUInt16(arg: String) -> UInt16? {
        var value: UInt32 = 0
        if NSScanner(string: arg).scanHexInt(&value) {
            if value > 0xffff {
                return nil
            }
            return UInt16(value & 0xffff)
        } else {
            return nil
        }
    }
    
    func cmdMMU(args: [String]?) {
        let c02mmuState = c02emuMMUState(emulator.emuState)
        for (reg, bank) in enumerate(emulator.state.mmu.page) {
            if bank < 0x80 {
                outputLine(NSString(format: "%04x RAM %05x", reg << 12, Int(bank) << 12))
            } else if bank < 0xc0 {
                outputLine(NSString(format: "%04x I/O %05x", reg << 12, Int(bank) << 12))
            } else {
                outputLine(NSString(format: "%04x ROM %05x", reg << 12, Int(bank) << 12))
            }
        }
    }
}
