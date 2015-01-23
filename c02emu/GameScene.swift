//
//  GameScene.swift
//  c02emu
//
//  Created by Pelle on 2015-01-06.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, NSWindowDelegate {
    
    var screenCharNodes: [SKSpriteNode!]!
    var charTextures: [SKTexture!]!
    var emulator: EmulatorController! = nil
    
    var keyboardModifiers = NSEvent.modifierFlags()
    
    override func didMoveToView(view: SKView) {
        let charsetImage80x50 = NSImage(named: "Charset-80x50")!
        let charWidth = Int(charsetImage80x50.size.width) / 32
        let charHeight = Int(charsetImage80x50.size.height) / 8
        var charsetProperties80x50 = [String:NSImage]()
        for i in 0..<256 {
            let x = (i % 32) * charWidth
            let y = (7 - i / 32) * charHeight
            let charRect = CGRect(x: x, y: y, width: charWidth, height: charHeight)
            let charImage = NSImage(size: NSSize(width: charWidth, height: charHeight))
            charImage.lockFocus()
            charsetImage80x50.drawAtPoint(NSPoint(x: 0, y: 0), fromRect: charRect, operation: .CompositeCopy, fraction: 1.0)
            charImage.unlockFocus()
            charsetProperties80x50[String(format:"char_%03d", i)] = charImage
        }
        let atlas80x50 = SKTextureAtlas(dictionary: charsetProperties80x50)
        charTextures = []
        for i in 0..<256 {
            let texture = atlas80x50.textureNamed(String(format:"char_%03d", i))
            texture.filteringMode = .Nearest
            charTextures.append(texture)
        }
        screenCharNodes = []
        for y in 0..<50 {
            for x in 0..<80 {
                let i = (y % 8) * 32 + x % 32
                let sprite = SKSpriteNode(texture: charTextures[i])
                sprite.anchorPoint = CGPointZero
                sprite.position = CGPoint(x: x*8, y: 400 - y*8 - 8)
                sprite.size = CGSize(width: 8, height: 8)
                self.addChild(sprite)
                screenCharNodes.append(sprite)
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        if let frame = emulator?.nextQueuedFrame() {
            for i in 0..<80 * 50 {
                screenCharNodes[i].texture = charTextures[Int(frame.displayData[i])]
            }
        }
    }
    
    
    override func keyDown(theEvent: NSEvent) {
        NSLog(String(format: "keyDown(0x%02x)", theEvent.keyCode))
        scanModifiers(theEvent.modifierFlags)
        if let keyCode = macKeyCodes[theEvent.keyCode] {
            emulator.keyDown(keyCode)
        }
    }
    
    override func keyUp(theEvent: NSEvent) {
        NSLog(String(format: "keyDown(0x%02x)", theEvent.keyCode))
        if let keyCode = macKeyCodes[theEvent.keyCode] {
            emulator.keyUp(keyCode)
        }
        scanModifiers(theEvent.modifierFlags)
    }
    
    func scanModifiers(flags: NSEventModifierFlags) {
        if flags != keyboardModifiers {
            NSLog("flags: \(flags.rawValue)")
        }
        let changes = keyboardModifiers ^ flags
        
        if changes.rawValue & NSEventModifierFlags.ShiftKeyMask.rawValue != 0 {
            if flags.rawValue & NSEventModifierFlags.ShiftKeyMask.rawValue != 0 {
                emulator.keyDown(.LeftShift)
            } else {
                emulator.keyUp(.LeftShift)
            }
        } else if changes.rawValue & NSEventModifierFlags.ControlKeyMask.rawValue != 0 {
            if flags.rawValue & NSEventModifierFlags.ControlKeyMask.rawValue != 0 {
                emulator.keyDown(.LeftControl)
            } else {
                emulator.keyUp(.LeftControl)
            }
        } else if changes.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue != 0 {
            if flags.rawValue & NSEventModifierFlags.AlternateKeyMask.rawValue != 0 {
                emulator.keyDown(.LeftAlt)
            } else {
                emulator.keyUp(.LeftAlt)
            }
        } else if changes.rawValue & NSEventModifierFlags.AlphaShiftKeyMask.rawValue != 0 {
            if flags.rawValue & NSEventModifierFlags.AlphaShiftKeyMask.rawValue != 0 {
                emulator.keyDown(.CapsLock)
            } else {
                emulator.keyUp(.CapsLock)
            }
        }
        
        keyboardModifiers = flags
    }
    
    let macKeyCodes: [UInt16:Keyboard.KeyCode] = [
        
        0x0a: .Backtick,
        0x12: .Digit1,
        0x13: .Digit2,
        0x14: .Digit3,
        0x15: .Digit4,
        0x17: .Digit5,
        0x16: .Digit6,
        0x1A: .Digit7,
        0x1C: .Digit8,
        0x19: .Digit9,
        0x1D: .Digit0,
        0x1B: .Minus,
        0x18: .Equal,
        0x74: .PageUp,
        0x73: .Home,
        0x33: .Backspace,
        
        0x0c: .Q,
        0x0d: .W,
        0x0e: .E,
        0x0f: .R,
        0x11: .T,
        0x10: .Y,
        0x20: .U,
        0x22: .I,
        0x1f: .O,
        0x23: .P,
        0x21: .LeftBracket,
        0x1E: .RightBracket,
        0x79: .PageDown,
        
        0x00: .A,
        0x01: .S,
        0x02: .D,
        0x03: .F,
        0x05: .G,
        0x04: .H,
        0x26: .J,
        0x28: .K,
        0x25: .L,
        0x29: .Semicolon,
        0x27: .Apostrophe,
        0x2a: .Backslash,
        0x24: .Enter,
        
        0x32: .LessThan,
        0x06: .Z,
        0x07: .X,
        0x08: .C,
        0x09: .V,
        0x0B: .B,
        0x2D: .N,
        0x2E: .M,
        0x2B: .Comma,
        0x2F: .Period,
        0x2C: .Slash,
        0x7E: .Up,
        0x7D: .Down,
        0x7B: .Left,
        0x7C: .Right,
        
        0x31: .Space,
        
        0x7A: .F1,
        0x78: .F2,
        0x63: .F3,
        0x76: .F4,
        0x60: .F5,
        0x61: .F6,
        0x62: .F7,
        0x64: .F8,
        0x65: .F9,
        0x6D: .F10,
        0x67: .F11,
        0x6F: .F12,
        // 0x69: .F13,
        // 0x6B: .F14,
        // 0x71: .F15,
        // 0x6A: .F16,
        // 0x40: .F17,
        // 0x4F: .F18,
        // 0x50: .F19,
        // 0x5A: .F20,
        
        0x39: .CapsLock,
        0x37: .LeftGUI,
        0x3B: .LeftControl,
        0x77: .End,
        0x35: .Escape,
        0x75: .Delete,
        // 0x3F: .Function,
        // 0x72: .Help,
        // 0x4A: .Mute,
        0x3A: .LeftAlt,
        0x3E: .RightControl,
        0x3D: .RightAlt,
        0x3C: .RightShift,
        0x38: .LeftShift,
        0x30: .Tab,
        // 0x49: .VolumeDown,
        // 0x48: .VolumeUp,
        
        0x47: .NumLock,
        0x51: .KeypadSlash,
        0x4B: .KeypadStar,
        0x43: .KeypadMinus,
        // 0x4E: KeypadMinus,
        0x45: .KeypadPlus,
        0x4C: .KeypadEnter,
        0x41: .KeypadPeriod,
        0x52: .Keypad0,
        0x53: .Keypad1,
        0x54: .Keypad2,
        0x55: .Keypad3,
        0x56: .Keypad4,
        0x57: .Keypad5,
        0x58: .Keypad6,
        0x59: .Keypad7,
        0x5B: .Keypad8,
        0x5C: .Keypad9,
    ]

}
