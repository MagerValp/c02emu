//
//  MonitorWindowController.swift
//  c02emu
//
//  Created by Pelle on 2015-01-13.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa


class MonitorWindowController: NSObject, NSTextFieldDelegate, MonitorDelegate {

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
    var printQueue = [NSAttributedString]()
    let printDispatchQueue = dispatch_queue_create("se.automac.MonitorWindowController", nil)
    var updateTimer: NSTimer?
    
    var commandHistory = [String]()
    var commandHistoryPosition = 0
    var commandBuffer = ""
    
    var busy = false
    
    override func awakeFromNib() {
        emulator.monitor.delegate = self
        
        inputField.delegate = self
        outputView.editable = false
        
        commonAttr[NSFontAttributeName] = regularFont
        
        promptAttr.addEntriesFromDictionary(commonAttr)
        
        inputAttr.addEntriesFromDictionary(commonAttr)
        inputAttr[NSFontAttributeName] = boldFont
        
        outputAttr.addEntriesFromDictionary(commonAttr)
        
        errorAttr.addEntriesFromDictionary(commonAttr)
        errorAttr[NSForegroundColorAttributeName] = NSColor.redColor()
        
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(1.0/30.0, target: self, selector: "flushPrintQueue", userInfo: nil, repeats: true)
    }
    
    func print(str: String, attributes: [NSObject:AnyObject]?) {
        dispatch_sync(printDispatchQueue) {
            self.printQueue.append(NSAttributedString(string: str, attributes: attributes))
        }
    }
    
    func flushPrintQueue() {
        var messages = [NSAttributedString]()
        if printQueue.count > 0 {
            dispatch_sync(printDispatchQueue) {
                messages = self.printQueue
                self.printQueue.removeAll(keepCapacity: true)
            }
            if messages.count > 1 {
                var joinedMessages = NSMutableAttributedString(attributedString: messages.first!)
                for i in 1..<messages.count {
                    joinedMessages.appendAttributedString(messages[i])
                }
                outputView.textStorage?.appendAttributedString(joinedMessages)
            } else {
                outputView.textStorage?.appendAttributedString(messages.first!)
            }
            outputView.scrollToEndOfDocument(self)
        }
    }
    
    func outputMessage(msg: String) {
        self.print(msg, attributes: self.outputAttr)
    }
    
    func outputError(msg: String) {
        self.print(msg, attributes: self.errorAttr)
    }
    
    func exitMonitor() {
        emulator.action = previousAction
        hide()
    }
    
    func willExecuteCommand() {
        busy = true
        window.standardWindowButton(.CloseButton)!.enabled = false
    }
    
    func didExecuteCommand() {
        window.standardWindowButton(.CloseButton)!.enabled = true
        busy = false
    }
    
    @IBAction func toggleWindow(sender: AnyObject) {
        if window.visible {
            if !busy {
                emulator.action = previousAction
                hide()
            }
        } else {
            if emulator.action == .Run || emulator.action == .Pause {
                previousAction = emulator.action
                emulator.action = .Monitor
                show()
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), {
                    self.emulator.monitor.executeCommand("__ENTER_MONITOR")
                })
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
        if !busy {
            commandBuffer = inputField.stringValue
            if commandBuffer != "" {
                inputField.stringValue = ""
                
                commandHistory.append(commandBuffer)
                commandHistoryPosition = commandHistory.count
                
                print("> ", attributes: promptAttr)
                print(commandBuffer, attributes: inputAttr)
                print("\n", attributes: promptAttr)
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), {
                    self.emulator.monitor.executeCommand(self.commandBuffer)
                })
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
