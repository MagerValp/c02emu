//
//  EmulatorController.swift
//  c02emu
//
//  Created by Pelle on 2015-01-15.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa


class EmulatorController: NSObject, DisassemblerDelegate {

    enum DisplayMode: Int {
        case Text40x25 = 0
        case Text80x25 = 1
        case Text40x50 = 2
        case Text80x50 = 3
    }
    
    struct Frame {
        var displayMode: DisplayMode!
        var displayData: [UInt8]!
    }
    
    enum Action {
        case Stop
        case Run
        case Pause
        case Monitor
    }
    
    let emuState: COpaquePointer
    let monitor: Monitor!
    
    var frameQueue = [Frame]()
    let frameQueueMax = 6
    let frameDispatchQueue = dispatch_queue_create("se.automac.EmulatorController", nil)
    
    var action = Action.Stop
    
    override init() {
        emuState = c02emuCreate()
        super.init()
        monitor = Monitor(emulator: self)
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
                        assertionFailure("Unexpected c02emuRun reason")
                    }
                }
            }
        }
    }
    
    func step() {
        stepLoop: for ;; {
            switch c02emuStepCycle(emuState).value {
            case C02EMU_FRAME_READY.value:
                let frame = self.buildFrame()
                dispatch_sync(frameDispatchQueue, {
                    self.frameQueue.append(frame)
                })
                return
            case C02EMU_CPU_STOPPED.value:
                continue
            case C02EMU_CYCLE_STEPPED.value:
                return
            default:
                assertionFailure("Unexpected c02emuStep reason")
            }
        }
    }
    
    func buildFrame() -> Frame {
        var frame: Frame
        
        let output = c02emuGetOutput(emuState)
        
        switch output.display.mode.value {
            
        case C02EMU_DISPLAY_MODE_TEXT_80X50.value:
            let buffer = UnsafeBufferPointer<UInt8>(start: output.display.data, count: 4000)
            frame = Frame(displayMode: .Text80x50, displayData: [UInt8](buffer))
        default:
            assertionFailure("Unimplemented display mode")
        }
        
        return frame
    }
    
    func nextQueuedFrame() -> Frame? {
        var frame: Frame! = nil
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
    
    
    // Monitor support.
    
    enum CPUOPState: Int, Printable {
        case Cycle1=0
        case Cycle2
        case Cycle3
        case Cycle4
        case Cycle5
        case Cycle6
        case Cycle7
        case Cycle8
        case FetchingOp
        case Stopped
        case Waiting
        
        var description: String {
            get {
                switch self {
                case Cycle1:
                    return "Cycle 1"
                case Cycle2:
                    return "Cycle 2"
                case Cycle3:
                    return "Cycle 3"
                case Cycle4:
                    return "Cycle 4"
                case Cycle5:
                    return "Cycle 5"
                case Cycle6:
                    return "Cycle 6"
                case Cycle7:
                    return "Cycle 7"
                case Cycle8:
                    return "Cycle 8"
                case FetchingOp:
                    return "Fetching op"
                case Stopped:
                    return "Stopped"
                case Waiting:
                    return "Waiting"
                }
            }
        }

    }
    
    struct CPUState {
        let a: UInt8
        let x: UInt8
        let y: UInt8
        let stack: UInt8
        let status: UInt8
        let pc: UInt16
        
        let ir: UInt8
        let state: CPUOPState
    }
    
    struct MMUState {
        let page: [UInt8]
    }
    
    struct DisplayState {
        let cycle: UInt
        let line: UInt
        let frame: UInt
    }
    
    struct EmulatorState {
        let cpu: CPUState
        let mmu: MMUState
        let display: DisplayState
    }
    
    var state: EmulatorState {
        get {
            let c02cpuRegs = c02emuCPURegs(emuState)
            let c02cpuState = c02emuCPUState(emuState)
            let cpuState = CPUState(a: c02cpuRegs.a,
                x: c02cpuRegs.x,
                y: c02cpuRegs.y,
                stack: c02cpuRegs.stack,
                status: c02cpuRegs.status,
                pc: c02cpuRegs.pc,
                ir: c02cpuState.ir,
                state: CPUOPState(rawValue: Int(c02cpuState.op_state.value))!)
            
            let c02mmuState = c02emuMMUState(emuState)
            // I really wish Swift didn't interpret C arrays as tuples.
            let page = [
                c02mmuState.page.0,
                c02mmuState.page.1,
                c02mmuState.page.2,
                c02mmuState.page.3,
                c02mmuState.page.4,
                c02mmuState.page.5,
                c02mmuState.page.6,
                c02mmuState.page.7,
                c02mmuState.page.8,
                c02mmuState.page.9,
                c02mmuState.page.10,
                c02mmuState.page.11,
                c02mmuState.page.12,
                c02mmuState.page.13,
                c02mmuState.page.14,
                c02mmuState.page.15,
            ]
            let mmuState = MMUState(page: page)
            
            let c02displayState = c02emuDisplayState(emuState)
            let displayState = DisplayState(cycle: UInt(c02displayState.cycle_ctr), line: UInt(c02displayState.line_ctr), frame: UInt(c02displayState.frame_ctr))
            
            return EmulatorState(cpu: cpuState, mmu: mmuState, display: displayState)
        }
    }
    
    func readMemory(addr: UInt16) -> UInt8 {
        return c02emuCPURead(emuState, addr)
    }
    
}
