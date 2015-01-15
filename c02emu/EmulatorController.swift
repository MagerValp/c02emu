//
//  EmulatorController.swift
//  c02emu
//
//  Created by Pelle on 2015-01-15.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa


enum EmulatorDisplayMode: Int {
    case Text40x25 = 0
    case Text80x25 = 1
    case Text40x50 = 2
    case Text80x50 = 3
}

struct EmulatorFrame {
    var displayMode: EmulatorDisplayMode!
    var displayData: [UInt8]!
}

enum EmulatorAction {
    case Stop
    case Run
    case Pause
}

class EmulatorController: NSObject {

    let emuState: COpaquePointer
    var frameQueue = [EmulatorFrame]()
    let frameQueueMax = 6
    let frameDispatchQueue = dispatch_queue_create("se.automac.EmulatorController", nil)
    
    var action = EmulatorAction.Stop
    
    override init() {
        emuState = c02emuCreate()
    }
    
    deinit {
        c02emuDestroy(emuState)
    }
    
    func configure() {
        loadROM()
    }
    
    func start() {
        c02emuReset(emuState)
        action = .Run
        run()
    }
    
    func stop() {
    }
    
    func run() {
        if action == .Run {
            if frameQueue.count < frameQueueMax {
                runLoop: for ;; {
                    switch c02emuRun(emuState).value {
                    case C02EMU_FRAME_READY.value:
                        let frame = self.buildFrame()
                        dispatch_sync(frameDispatchQueue, {
                            self.frameQueue.append(frame)
                        })
                        break runLoop
                    case C02EMU_CPU_STOPPED.value:
                        continue
                    default:
                        assertionFailure("Unimplemented c02emuRun reason")
                    }
                }
            }
        }
    }

    func buildFrame() -> EmulatorFrame {
        var frame: EmulatorFrame
        
        let output = c02emuGetOutput(emuState)
        
        switch output.display.mode.value {
            
        case C02EMU_DISPLAY_MODE_TEXT_80X50.value:
            let buffer = UnsafeBufferPointer<UInt8>(start: output.display.data, count: 4000)
            frame = EmulatorFrame(displayMode: .Text80x50, displayData: [UInt8](buffer))
        default:
            assertionFailure("Unimplemented display mode")
        }
        
        return frame
    }
    
    func nextQueuedFrame() -> EmulatorFrame? {
        var frame: EmulatorFrame! = nil
        if frameQueue.count > 0 {
            dispatch_sync(frameDispatchQueue, {
                frame = self.frameQueue.removeAtIndex(0)
            })
            run()
            return frame
        } else {
            run()
            return nil
        }
    }
    
    @IBAction func togglePause(sender: AnyObject) {
        if action == .Run {
            NSLog("pausing")
            action = .Pause
        } else if action == .Pause {
            NSLog("running")
            action = .Run
        }
    }
    
    // Configuration.
    
    func loadROM() {
        loadROM(NSData(contentsOfURL: NSBundle.mainBundle().URLForResource("rom", withExtension: "bin")!)!)
    }
    
    func loadROM(romData: NSData) {
        c02emuLoadROM(emuState, romData.bytes, UInt(romData.length))
    }
    
}
