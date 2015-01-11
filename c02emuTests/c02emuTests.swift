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
        //   IRQ vector set to $0406
        //   NMI vector set to $0403
        //   RES vector set to $0400.
        rom = NSMutableData()
        rom.appendData(NSMutableData(length: 0x1000 - 6)!)
        rom.appendBytes([0x03, 0x04] as [Byte], length: 2)
        rom.appendBytes([0x00, 0x04] as [Byte], length: 2)
        rom.appendBytes([0x06, 0x04] as [Byte], length: 2)
        c02emuLoadROM(emuState, rom.bytes, UInt(rom.length))
        // Set program load PC to $0400.
        prgPtr = 0x0400
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
    
    func loadBin(addr: Int, data: UnsafePointer<Void>, length: Int) {
        NSLog("Loading \(length) bytes at \(addr)")
        let bytes = UnsafePointer<Byte>(data)
        for i in 0..<length {
            c02emuCPUWrite(emuState, UInt16(addr + i), bytes[i])
        }
    }
    
//    func testCPURegLoad() {
//        // IRQ
//        setProgramBytes([0xdb, 0xdb, 0xdb]) // stp/stp/stp
//        // NMI
//        setProgramBytes([0xdb, 0xdb, 0xdb]) // stp/stp/stp
//        // RES
//        setProgramBytes([0xA2, 0x7F, 0x9a]) // ldx #$7f, txs
//        setProgramBytes([0xA9, 0x12])       // lda #$12
//        setProgramBytes([0xA2, 0x34])       // ldx #$34
//        setProgramBytes([0xA0, 0x56])       // ldy #$56
//        setProgramBytes([0xC9, 0x13])       // cmp #$13
//        setProgramBytes([0xdb])             // stp
//        c02emuReset(emuState)
//        
//        let reason = c02emuRun(emuState)
//        XCTAssertEqual(reason.value, C02EMU_CPU_STOPPED.value, "reason")
//        
//        let cpu = c02emuCPURegs(emuState)
//        XCTAssertEqual(Int(cpu.memory.a), Int(0x12), "LDA")
//        XCTAssertEqual(Int(cpu.memory.x), Int(0x34), "LDX")
//        XCTAssertEqual(Int(cpu.memory.y), Int(0x56), "LDY")
//        XCTAssertEqual(Int(cpu.memory.status) & 0xc1, 0x80, "CMP")
//    }
    
    func chr(c: String) -> UInt8 {
        return [UInt8](c.utf8)[0]
    }
    
    func testDebugOutput() {
        setProgramBytes([0xa9, chr("H")])       // lda #'H'
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xa9, chr("e")])       // lda #'e'
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xa9, chr("l")])       // lda #'l'
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xa9, chr("l")])       // lda #'l'
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xa9, chr("o")])       // lda #'o'
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xa9, 0x0d])       // lda #$0d
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xa9, 0x0a])       // lda #$0a
        setProgramBytes([0x8d, 0x00, 0xef]) // sta $ef00
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)

        let reason = c02emuRun(emuState)
        XCTAssertEqual(reason.value, C02EMU_CPU_STOPPED.value, "reason")
    }
    
    func testDisplayOutput() {
        setProgramBytes([0xa9, 0x00])       // lda #0
        setProgramBytes([0x8d, 0x00, 0xe3]) // sta $e300
        setProgramBytes([0xa9, chr("H")])       // lda #'H'
        setProgramBytes([0x8d, 0x00, 0xe2]) // sta $e200
        setProgramBytes([0xa9, chr("e")])       // lda #'e'
        setProgramBytes([0x8d, 0x01, 0xe2]) // sta $e201
        setProgramBytes([0xa9, chr("l")])       // lda #'l'
        setProgramBytes([0x8d, 0x02, 0xe2]) // sta $e202
        setProgramBytes([0xa9, chr("l")])       // lda #'l'
        setProgramBytes([0x8d, 0x03, 0xe2]) // sta $e203
        setProgramBytes([0xa9, chr("o")])       // lda #'o'
        setProgramBytes([0x8d, 0x04, 0xe2]) // sta $e204
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        
        let reason = c02emuRun(emuState)
        XCTAssertEqual(reason.value, C02EMU_CPU_STOPPED.value, "reason")
        
        let output = c02emuGetOutput(emuState)
        XCTAssertEqual(UInt8(output.display.data[0]), chr("H"), "H")
        XCTAssertEqual(UInt8(output.display.data[1]), chr("e"), "e")
        XCTAssertEqual(UInt8(output.display.data[2]), chr("l"), "l")
        XCTAssertEqual(UInt8(output.display.data[3]), chr("l"), "l")
        XCTAssertEqual(UInt8(output.display.data[4]), chr("o"), "o")

    }
    
    func test6502FuncTest() {
        var frame = 0
        
        let bundle = NSBundle(forClass: self.dynamicType)
        if let romData = NSData(contentsOfURL: bundle.URLForResource("6502_functional_test", withExtension: "bin")!) {
            loadBin(0x0400, data: romData.bytes, length: romData.length)
        } else {
            XCTAssertTrue(false, "Couldn't load 6502_functional_test.bin")
        }
        c02emuReset(emuState)
        while c02emuRun(emuState).value == C02EMU_FRAME_READY.value {
            //NSLog("Frame: \(frame++)")
        }
    }
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
