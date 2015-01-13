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
    let font = NSFont(name: "menlo", size: 10.0)
    var textAttr = [String: AnyObject]()
    var commandHistory = [String]()
    var commandHistoryPosition = 0
    var commandBuffer = ""
    
    override func awakeFromNib() {
        inputField.delegate = self
        textAttr[NSFontAttributeName] = font
        outputView.editable = false
        //outputView.textStorage?.setAttributedString(NSAttributedString(string: "c02 monitor\n", attributes: textAttr))
    }
    
    @IBAction func toggleWindow(sender: AnyObject) {
        if window.visible {
            hide()
        } else {
            show()
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
            
            outputView.textStorage?.appendAttributedString(NSAttributedString(string: "> \(commandBuffer)\n", attributes: textAttr))
            
            parseCommand(commandBuffer)
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
    
//    override func controlTextDidChange(obj: NSNotification) {
//        NSLog("controlTextDidChange")
//    }
    
    func parseCommand(command: String) {
        
    }
}
