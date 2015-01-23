//
//  Keyboard.swift
//  c02emu
//
//  Created by Per Olofsson on 2015-01-23.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa

class Keyboard {

    enum KeyCode {
        case A
        case B
        case C
        case D
        case E
        case F
        case G
        case H
        case I
        case J
        case K
        case L
        case M
        case N
        case O
        case P
        case Q
        case R
        case S
        case T
        case U
        case V
        case W
        case X
        case Y
        case Z
        case Digit0
        case Digit1
        case Digit2
        case Digit3
        case Digit4
        case Digit5
        case Digit6
        case Digit7
        case Digit8
        case Digit9
        case Backtick
        case Minus
        case Equal
        case Backslash
        case Backspace
        case Space
        case Tab
        case LessThan
        case CapsLock
        case LeftShift
        case LeftControl
        case LeftGUI
        case LeftAlt
        case RightShift
        case RightControl
        case RightGUI
        case RightAlt
        case Apps
        case Enter
        case Escape
        case F1
        case F2
        case F3
        case F4
        case F5
        case F6
        case F7
        case F8
        case F9
        case F10
        case F11
        case F12
        case PrintScreen
        case ScrollLock
        case Pause
        case LeftBracket
        case RightBracket
        case Semicolon
        case Apostrophe
        case Comma
        case Period
        case Slash
        case Insert
        case Home
        case PageUp
        case Delete
        case End
        case PageDown
        case Up
        case Left
        case Down
        case Right
        case NumLock
        case KeypadSlash
        case KeypadStar
        case KeypadMinus
        case KeypadPlus
        case KeypadEnter
        case KeypadPeriod
        case Keypad0
        case Keypad1
        case Keypad2
        case Keypad3
        case Keypad4
        case Keypad5
        case Keypad6
        case Keypad7
        case Keypad8
        case Keypad9
    }
    
    class func ps2MakeCode(key: KeyCode) -> [UInt8]? {
        let ps2make: [KeyCode:[UInt8]] = [
            .A:             [0x1c],
            .B:             [0x32],
            .C:             [0x21],
            .D:             [0x23],
            .E:             [0x24],
            .F:             [0x2b],
            .G:             [0x34],
            .H:             [0x33],
            .I:             [0x43],
            .J:             [0x3b],
            .K:             [0x42],
            .L:             [0x4b],
            .M:             [0x3a],
            .N:             [0x31],
            .O:             [0x44],
            .P:             [0x4d],
            .Q:             [0x15],
            .R:             [0x2d],
            .S:             [0x1b],
            .T:             [0x2c],
            .U:             [0x3c],
            .V:             [0x2a],
            .W:             [0x1d],
            .X:             [0x22],
            .Y:             [0x35],
            .Z:             [0x1a],
            .Digit0:        [0x45],
            .Digit1:        [0x16],
            .Digit2:        [0x1e],
            .Digit3:        [0x26],
            .Digit4:        [0x25],
            .Digit5:        [0x2e],
            .Digit6:        [0x36],
            .Digit7:        [0x3d],
            .Digit8:        [0x3e],
            .Digit9:        [0x46],
            .Backtick:      [0x0e],
            .Minus:         [0x4e],
            .Equal:         [0x55],
            .Backslash:     [0x5d],
            .Backspace:     [0x66],
            .Space:         [0x29],
            .Tab:           [0x0d],
            .LessThan:      [0x61],
            .CapsLock:      [0x58],
            .LeftShift:     [0x12],
            .LeftControl:   [0x14],
            .LeftGUI:       [0xe0, 0x1f],
            .LeftAlt:       [0x11],
            .RightShift:    [0x59],
            .RightControl:  [0xe0, 0x14],
            .RightGUI:      [0xe0, 0x27],
            .RightAlt:      [0xe0, 0x11],
            .Apps:          [0xe0, 0x2f],
            .Enter:         [0x5a],
            .Escape:        [0x76],
            .F1:            [0x05],
            .F2:            [0x06],
            .F3:            [0x04],
            .F4:            [0x0c],
            .F5:            [0x03],
            .F6:            [0x0b],
            .F7:            [0x83],
            .F8:            [0x0a],
            .F9:            [0x01],
            .F10:           [0x09],
            .F11:           [0x78],
            .F12:           [0x07],
            .PrintScreen:   [0xe0, 0x12, 0xe0, 0x7c],
            .ScrollLock:    [0x7e],
            .Pause:         [0xe1, 0x14, 0x77, 0xe1, 0xf0, 0x14, 0xf0, 0x77],
            .LeftBracket:   [0x54],
            .RightBracket:  [0x5b],
            .Semicolon:     [0x4c],
            .Apostrophe:    [0x52],
            .Comma:         [0x41],
            .Period:        [0x49],
            .Slash:         [0x4a],
            .Insert:        [0xe0, 0x70],
            .Home:          [0xe0, 0x6c],
            .PageUp:        [0xe0, 0x7d],
            .Delete:        [0xe0, 0x71],
            .End:           [0xe0, 0x69],
            .PageDown:      [0xe0, 0x7a],
            .Up:            [0xe0, 0x75],
            .Left:          [0xe0, 0x6b],
            .Down:          [0xe0, 0x72],
            .Right:         [0xe0, 0x74],
            .NumLock:       [0x77],
            .KeypadSlash:   [0xe0, 0x4a],
            .KeypadStar:    [0x7c],
            .KeypadMinus:   [0x7b],
            .KeypadPlus:    [0x79],
            .KeypadEnter:   [0xe0, 0x5a],
            .KeypadPeriod:  [0x71],
            .Keypad0:       [0x70],
            .Keypad1:       [0x69],
            .Keypad2:       [0x72],
            .Keypad3:       [0x7a],
            .Keypad4:       [0x6b],
            .Keypad5:       [0x73],
            .Keypad6:       [0x74],
            .Keypad7:       [0x6c],
            .Keypad8:       [0x75],
            .Keypad9:       [0x7d],
        ]
        return ps2make[key]
    }
    
    class func ps2BreakCode(key: KeyCode) -> [UInt8]? {
        let ps2break: [KeyCode:[UInt8]] = [
            .A:             [0xf0, 0x1c],
            .B:             [0xf0, 0x32],
            .C:             [0xf0, 0x21],
            .D:             [0xf0, 0x23],
            .E:             [0xf0, 0x24],
            .F:             [0xf0, 0x2b],
            .G:             [0xf0, 0x34],
            .H:             [0xf0, 0x33],
            .I:             [0xf0, 0x43],
            .J:             [0xf0, 0x3b],
            .K:             [0xf0, 0x42],
            .L:             [0xf0, 0x4b],
            .M:             [0xf0, 0x3a],
            .N:             [0xf0, 0x31],
            .O:             [0xf0, 0x44],
            .P:             [0xf0, 0x4d],
            .Q:             [0xf0, 0x15],
            .R:             [0xf0, 0x2d],
            .S:             [0xf0, 0x1b],
            .T:             [0xf0, 0x2c],
            .U:             [0xf0, 0x3c],
            .V:             [0xf0, 0x2a],
            .W:             [0xf0, 0x1d],
            .X:             [0xf0, 0x22],
            .Y:             [0xf0, 0x35],
            .Z:             [0xf0, 0x1a],
            .Digit0:        [0xf0, 0x45],
            .Digit1:        [0xf0, 0x16],
            .Digit2:        [0xf0, 0x1e],
            .Digit3:        [0xf0, 0x26],
            .Digit4:        [0xf0, 0x25],
            .Digit5:        [0xf0, 0x2e],
            .Digit6:        [0xf0, 0x36],
            .Digit7:        [0xf0, 0x3d],
            .Digit8:        [0xf0, 0x3e],
            .Digit9:        [0xf0, 0x46],
            .Backtick:      [0xf0, 0x0e],
            .Minus:         [0xf0, 0x4e],
            .Equal:         [0xf0, 0x55],
            .Backslash:     [0xf0, 0x5d],
            .Backspace:     [0xf0, 0x66],
            .Space:         [0xf0, 0x29],
            .Tab:           [0xf0, 0x0d],
            .LessThan:      [0xf0, 0x61],
            .CapsLock:      [0xf0, 0x58],
            .LeftShift:     [0xf0, 0x12],
            .LeftControl:   [0xf0, 0x14],
            .LeftGUI:       [0xe0, 0xf0, 0x1f],
            .LeftAlt:       [0xf0, 0x11],
            .RightShift:    [0xf0, 0x59],
            .RightControl:  [0xe0, 0xf0, 0x14],
            .RightGUI:      [0xe0, 0xf0, 0x27],
            .RightAlt:      [0xe0, 0xf0, 0x11],
            .Apps:          [0xe0, 0xf0, 0x2f],
            .Enter:         [0xf0, 0x5a],
            .Escape:        [0xf0, 0x76],
            .F1:            [0xf0, 0x05],
            .F2:            [0xf0, 0x06],
            .F3:            [0xf0, 0x04],
            .F4:            [0xf0, 0x0c],
            .F5:            [0xf0, 0x03],
            .F6:            [0xf0, 0x0b],
            .F7:            [0xf0, 0x83],
            .F8:            [0xf0, 0x0a],
            .F9:            [0xf0, 0x01],
            .F10:           [0xf0, 0x09],
            .F11:           [0xf0, 0x78],
            .F12:           [0xf0, 0x07],
            .PrintScreen:   [0xe0, 0xf0, 0x7c, 0xe0, 0xf0, 0x12],
            .ScrollLock:    [0xf0, 0x7e],
            .Pause:         [],
            .LeftBracket:   [0xf0, 0x54],
            .RightBracket:  [0xf0, 0x5b],
            .Semicolon:     [0xf0, 0x4c],
            .Apostrophe:    [0xf0, 0x52],
            .Comma:         [0xf0, 0x41],
            .Period:        [0xf0, 0x49],
            .Slash:         [0xf0, 0x4a],
            .Insert:        [0xe0, 0xf0, 0x70],
            .Home:          [0xe0, 0xf0, 0x6c],
            .PageUp:        [0xe0, 0xf0, 0x7d],
            .Delete:        [0xe0, 0xf0, 0x71],
            .End:           [0xe0, 0xf0, 0x69],
            .PageDown:      [0xe0, 0xf0, 0x7a],
            .Up:            [0xe0, 0xf0, 0x75],
            .Left:          [0xe0, 0xf0, 0x6b],
            .Down:          [0xe0, 0xf0, 0x72],
            .Right:         [0xe0, 0xf0, 0x74],
            .NumLock:       [0xf0, 0x77],
            .KeypadSlash:   [0xe0, 0xf0, 0x4a],
            .KeypadStar:    [0xf0, 0x7c],
            .KeypadMinus:   [0xf0, 0x7b],
            .KeypadPlus:    [0xf0, 0x79],
            .KeypadEnter:   [0xe0, 0xf0, 0x5a],
            .KeypadPeriod:  [0xf0, 0x71],
            .Keypad0:       [0xf0, 0x70],
            .Keypad1:       [0xf0, 0x69],
            .Keypad2:       [0xf0, 0x72],
            .Keypad3:       [0xf0, 0x7a],
            .Keypad4:       [0xf0, 0x6b],
            .Keypad5:       [0xf0, 0x73],
            .Keypad6:       [0xf0, 0x74],
            .Keypad7:       [0xf0, 0x6c],
            .Keypad8:       [0xf0, 0x75],
            .Keypad9:       [0xf0, 0x7d],
        ]
        return ps2break[key]
    }
    
}
