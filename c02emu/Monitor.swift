//
//  Monitor.swift
//  c02emu
//
//  Created by Pelle on 2015-01-15.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa

enum StringParserState: String {
    case Base = "Base"
    case EscapedCharacter = "EscapedCharacter"
    case DoubleQuotedString = "DoubleQuotedString"
    case EscapedCharacterInQuotes = "EscapedCharacterInQuotes"
    case SingleQuotedString = "SingleQuotedString"
}

class Monitor: NSObject {
    
    enum MonitorAction {
        case ExitMonitor
    }
    
    enum MonitorReturnValue {
        case Error(String)
        case Output(String)
        case Action(MonitorAction)
    }
    
    weak var emulator: EmulatorController!
    
    init(emulator theEmulator: EmulatorController) {
        emulator = theEmulator
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
    
    func executeCommand(cmdBuffer: String) -> MonitorReturnValue {
        output = []
        if let cmdTokens = parseCommand(cmdBuffer) {
            if cmdTokens.count == 0 {
                return .Error("")
            }
            
            let args: [String]? = cmdTokens.count > 1 ? Array(cmdTokens[1 ..< cmdTokens.count]) : nil
            
            switch cmdTokens[0] {
                
            case "__ENTER_MONITOR":
                return cmdEnterMonitor(args)
            
            case "x":
                return .Action(.ExitMonitor)
                
            case "r":
                return cmdShowRegs(args)
                
            default:
                return .Error("Unknown command (? for help)")
                
            }
        } else {
            return .Error("Syntax error")
        }
    }

    var output = [String]()
    
    func outputOK() -> MonitorReturnValue {
        return .Output("\n".join(output))
    }
    
    func outputError() -> MonitorReturnValue {
        return .Error("\n".join(output))
    }
    
    let flag_c = 0x01
    let flag_z = 0x02
    let flag_i = 0x04
    let flag_d = 0x08
    let flag_b = 0x10
    let flag_1 = 0x20
    let flag_v = 0x40
    let flag_n = 0x80
    
    
    func cmdEnterMonitor(args: [String]?) -> MonitorReturnValue {
        output.append(NSString(format: "***BREAK at frame %d line %d cycle %d",
            emulator.state.display.frame,
            emulator.state.display.line,
            emulator.state.display.cycle))
        return outputOK()
    }
    
    func cmdShowRegs(args: [String]?) -> MonitorReturnValue {
        output.append("PC   A  X  Y  S  nv1bdizc  IR  State")
        let state = emulator.state
        let status = NSString(format: "%d%d1%d%d%d%d%d",
            (Int(state.cpu.status) & flag_n) >> 7,
            (Int(state.cpu.status) & flag_v) >> 6,
            (Int(state.cpu.status) & flag_b) >> 4,
            (Int(state.cpu.status) & flag_d) >> 3,
            (Int(state.cpu.status) & flag_i) >> 2,
            (Int(state.cpu.status) & flag_z) >> 1,
            (Int(state.cpu.status) & flag_c))
        output.append(NSString(format: "%04x %02x %02x %02x %02x %@  %02x  %@",
            state.cpu.pc,
            state.cpu.a,
            state.cpu.x,
            state.cpu.y,
            state.cpu.stack,
            status,
            state.cpu.ir,
            state.cpu.state.description))
        
        return outputOK()
    }
}
