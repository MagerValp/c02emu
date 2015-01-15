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
        rom.appendBytes([0x03, 0x04] as [UInt8], length: 2)
        rom.appendBytes([0x00, 0x04] as [UInt8], length: 2)
        rom.appendBytes([0x06, 0x04] as [UInt8], length: 2)
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
    
    func setProgramBytes(bytes: Array<UInt8>) {
        for byte in bytes {
            c02emuCPUWrite(emuState, prgPtr++, byte)
        }
    }
    
    func loadBin(addr: Int, data: UnsafePointer<Void>, length: Int) {
        NSLog("Loading \(length) bytes at \(addr)")
        let bytes = UnsafePointer<UInt8>(data)
        for i in 0..<length {
            c02emuCPUWrite(emuState, UInt16(addr + i), bytes[i])
        }
    }
    
//    func testCPURegLoad() {
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
    
    func testDebugTrap() {
        setProgramBytes([0xa2, 0xff, 0x9a]) // ldx #$ff, txs
        setProgramBytes([0xa9, 0x12])       // lda #$12
        setProgramBytes([0x48])             // pha
        setProgramBytes([0xa2, 0x34])       // ldx #$34
        setProgramBytes([0xda])             // phx
        setProgramBytes([0xa0, 0x56])       // ldy #$56
        setProgramBytes([0x5a])             // phy
        setProgramBytes([0x8d, 0x02, 0xef]) // sta $ef02
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
    
    func testEORFlags() {
        setProgramBytes([0xa9, 0x00])       // lda #0
        setProgramBytes([0x48])             // pha
        setProgramBytes([0x28])             // plp
        setProgramBytes([0xa9, 0xc3])       // lda #$c3
        setProgramBytes([0x49, 0xc3, 0xe3]) // eor #$c3
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.a, UInt8(0), "A")
        XCTAssertEqual(regs.memory.status & 0xdf, UInt8(0x02), "S")
    }
    
    func testDecimalADC() {
        setProgramBytes([0xf8])             // sed
        setProgramBytes([0x38])             // sec
        setProgramBytes([0xa9, 0x99])       // lda #$99
        setProgramBytes([0x69, 0x99])       // adc #$99
        setProgramBytes([0x8d, 0x02, 0xef]) // sta $ef02
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.a, UInt8(0x99), "A")
        XCTAssertEqual(regs.memory.status | 0x20, UInt8(0x6d), "S")
    }

    func testDecimalSBC() {
        setProgramBytes([0xf8])             // sed
        setProgramBytes([0x18])             // clc
        setProgramBytes([0xa9, 0x99])       // lda #$99
        setProgramBytes([0xe9, 0x00])       // sbc #$00
        setProgramBytes([0x8d, 0x02, 0xef]) // sta $ef02
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.a, UInt8(0x98), "A")
        XCTAssertEqual(regs.memory.status | 0x20, UInt8(0xad), "S")
    }

    func testDEX() {
        setProgramBytes([0xa2, 0x03])       // ldx #$03
        setProgramBytes([0xca])             // dex
        setProgramBytes([0xca])             // dex
        setProgramBytes([0xca])             // dex
        setProgramBytes([0xca])             // dex
        setProgramBytes([0x8d, 0x02, 0xef]) // sta $ef02
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.x, UInt8(0xff), "X")
        XCTAssertEqual(regs.memory.status | 0x20, UInt8(0xa4), "S")
    }
    
    func testBRAForward() {
        setProgramBytes([0x80, 0x7f])       // bra $0481
        for i in 0..<254 {
            setProgramBytes([0xdb])             // stp
        }
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.pc, UInt16(0x482), "PC")
    }
    
    func testBRABackward() {
        setProgramBytes([0x4c, 0x00, 0x05]) // jmp $0500
        for i in 0..<253 {
            setProgramBytes([0xdb])             // stp
        }
        setProgramBytes([0x80, 0x80])       // bra $0482
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.pc, UInt16(0x483), "PC")
    }
    
    func testzpx() {
        setProgramBytes([0xa9, 0x55])       // lda #$55
        setProgramBytes([0x85, 0x80])       // sta $80
        setProgramBytes([0xa2, 0x00])       // ldx #$00
        setProgramBytes([0xa9, 0xaa])       // lda #$aa
        setProgramBytes([0x15, 0x80])       // ora $80,x
        setProgramBytes([0x36, 0x80])       // rol $80,x
        setProgramBytes([0x8d, 0x02, 0xef]) // sta $ef02
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.memory.a, UInt8(0xff), "A")
        XCTAssertEqual(regs.memory.status | 0x20, UInt8(0xa4), "S")
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
    
    func testCPUEmulationPerformance() {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let romData = NSData(contentsOfURL: bundle.URLForResource("6502_functional_test", withExtension: "bin")!) {
            loadBin(0x0400, data: romData.bytes, length: romData.length)
        } else {
            XCTAssertTrue(false, "Couldn't load 6502_functional_test.bin")
        }
        self.measureBlock() {
            c02emuReset(self.emuState)
            for i in 0..<120 {
                XCTAssertEqual(c02emuRun(self.emuState).value, C02EMU_FRAME_READY.value, "Should run until frame ready")
            }
        }
    }
    
}
