//
//  MonitorWindowController.swift
//  c02emu
//
//  Created by Pelle on 2015-01-13.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa


class MonitorWindowController: NSObject, NSTextFieldDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var inputField: NSTextField!
    @IBOutlet var outputView: NSTextView!
    @IBOutlet weak var emulator: EmulatorController!
    
    var previousAction: EmulatorController.Action = .Run
    
    let regularFont = NSFont(name: "Menlo-Regular", size: 10.0)
    let boldFont = NSFont(name: "Menlo-Bold", size: 10.0)
    var commonAttr = NSMutableDictionary()
    var promptAttr = NSMutableDictionary()
    var inputAttr  = NSMutableDictionary()
    var outputAttr = NSMutableDictionary()
    var errorAttr  = NSMutableDictionary()
    
    var commandHistory = [String]()
    var commandHistoryPosition = 0
    var commandBuffer = ""
    
    override func awakeFromNib() {
        inputField.delegate = self
        outputView.editable = false
        
        commonAttr[NSFontAttributeName] = regularFont
        
        promptAttr.addEntriesFromDictionary(commonAttr)
        
        inputAttr.addEntriesFromDictionary(commonAttr)
        inputAttr[NSFontAttributeName] = boldFont
        
        outputAttr.addEntriesFromDictionary(commonAttr)
        
        errorAttr.addEntriesFromDictionary(commonAttr)
        errorAttr[NSForegroundColorAttributeName] = NSColor.redColor()
    }
    
    func print(str: String, attributes: [NSObject:AnyObject]?) {
        outputView.textStorage?.appendAttributedString(NSAttributedString(string: str, attributes: attributes))
        outputView.scrollToEndOfDocument(self)
    }
    
    @IBAction func toggleWindow(sender: AnyObject) {
        if window.visible {
            emulator.action = previousAction
            hide()
        } else {
            if emulator.action == .Run || emulator.action == .Pause {
                previousAction = emulator.action
                emulator.action = .Monitor
                show()
                executeCommand("__ENTER_MONITOR")
            }
        }
    }
    
    func show() {
        window.makeKeyAndOrderFront(self)
        inputField.becomeFirstResponder()
    }
    
    func hide() {
        window.orderOut(self)
    }
    
    @IBAction func enteredCommand(sender: NSTextField) {
        commandBuffer = inputField.stringValue
        if commandBuffer != "" {
            inputField.stringValue = ""
            
            commandHistory.append(commandBuffer)
            commandHistoryPosition = commandHistory.count
            
            print("> ", attributes: promptAttr)
            print(commandBuffer, attributes: inputAttr)
            print("\n", attributes: promptAttr)
            
            executeCommand(commandBuffer)
        }
    }
    
    func executeCommand(commandBuffer: String) {
        switch emulator.monitor.executeCommand(commandBuffer) {
            
        case .Output(let str):
            print(str, attributes: outputAttr)
            print("\n", attributes: outputAttr)
            
        case .Error(let str):
            print(str, attributes: errorAttr)
            print("\n", attributes: errorAttr)
            
        case .Action(let action):
            if action == .ExitMonitor {
                emulator.action = previousAction
                hide()
            }
        }
    }
    
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        if commandSelector == "moveUp:" {
            if commandHistory.count > 0 {
                if commandHistoryPosition >= commandHistory.count {
                    commandBuffer = inputField.stringValue
                    commandHistoryPosition = commandHistory.count - 1
                    inputField.stringValue = commandHistory.last!
                } else if commandHistoryPosition > 0 {
                    inputField.stringValue = commandHistory[--commandHistoryPosition]
                }
            }
        } else if commandSelector == "moveDown:" {
            if commandHistoryPosition < commandHistory.count {
                if ++commandHistoryPosition >= commandHistory.count {
                    inputField.stringValue = commandBuffer
                } else {
                    inputField.stringValue = commandHistory[commandHistoryPosition]
                }
            }
        } else {
            return false
        }
        return true
    }

}
