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
}
