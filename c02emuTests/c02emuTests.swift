//
//  c02emuTests.swift
//  c02emuTests
//
//  Created by Pelle on 2015-01-06.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import Cocoa
import XCTest

class c02emuTests: XCTestCase {
    
    var emuState: COpaquePointer = nil
    var rom: NSMutableData!
    var prgPtr: UInt16 = 0
    
    //var bundle: NSBundle!
    
    override func setUp() {
        super.setUp()
        emuState = c02emuCreate()
        // Load a dummy ROM with:
        //   IRQ vector set to $1000
        //   NMI vector set to $1003
        //   RES vector set to $1006.
        rom = NSMutableData()
        rom.appendData(NSMutableData(length: 0x1000 - 6)!)
        rom.appendBytes([0x03, 0x10] as [Byte], length: 2)
        rom.appendBytes([0x06, 0x10] as [Byte], length: 2)
        rom.appendBytes([0x00, 0x10] as [Byte], length: 2)
        // Set program load PC to $1000.
        prgPtr = 0x1000
        //bundle = NSBundle(forClass: self.dynamicType)
    }
    
    override func tearDown() {
        c02emuDestroy(emuState)
        emuState = nil
        super.tearDown()
    }
    
    func setProgramBytes(bytes: Array<Byte>) {
        for byte in bytes {
            c02emuCPUWrite(emuState, prgPtr++, byte)
        }
    }
    
    func testCPURegLoad() {
        // IRQ
        setProgramBytes([0xdb, 0xdb, 0xdb]) // stp/stp/stp
        // NMI
        setProgramBytes([0xdb, 0xdb, 0xdb]) // stp/stp/stp
        // RES
        setProgramBytes([0xA2, 0x7F, 0x9a]) // ldx #$7f, txs
        setProgramBytes([0xA9, 0x12])       // lda #$12
        setProgramBytes([0xA2, 0x34])       // ldx #$34
        setProgramBytes([0xA0, 0x56])       // ldy #$56
        setProgramBytes([0xC9, 0x13])       // cmp #$13
        setProgramBytes([0xdb])             // stp
        c02emuLoadROM(emuState, rom.bytes, UInt(rom.length))
        c02emuReset(emuState)
        
        let reason = c02emuRun(emuState)
        XCTAssertEqual(reason.value, C02EMU_CPU_STOPPED.value, "reason")
        
        let cpu = c02emuCPURegs(emuState)
        XCTAssertEqual(Int(cpu.memory.a), Int(0x12), "LDA")
        XCTAssertEqual(Int(cpu.memory.x), Int(0x34), "LDX")
        XCTAssertEqual(Int(cpu.memory.y), Int(0x56), "LDY")
        XCTAssertEqual(Int(cpu.memory.status) & 0xc1, 0x80, "CMP")
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
