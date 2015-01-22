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
        //   IRQ vector set to $1006
        //   NMI vector set to $1003
        //   RES vector set to $1000.
        rom = NSMutableData()
        rom.appendData(NSMutableData(length: 0x1000 - 6)!)
        rom.appendBytes([0x03, 0x10] as [UInt8], length: 2)
        rom.appendBytes([0x00, 0x10] as [UInt8], length: 2)
        rom.appendBytes([0x06, 0x10] as [UInt8], length: 2)
        c02emuLoadROM(emuState, rom.bytes, UInt(rom.length))
        // Set program load PC to $1000.
        prgPtr = 0x1000
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
        setProgramBytes([0x8d, 0x00, 0xe0]) // sta $e300
        setProgramBytes([0x8d, 0x02, 0xe0]) // sta $e302
        setProgramBytes([0x8d, 0x03, 0xe0]) // sta $e303
        setProgramBytes([0xa9, 0x10])       // lda #$10
        setProgramBytes([0x8d, 0x01, 0xe0]) // sta $e301
        setProgramBytes([0xa9, chr("H")])   // lda #'H'
        setProgramBytes([0x8d, 0x00, 0x10]) // sta $1000
        setProgramBytes([0xa9, chr("e")])   // lda #'e'
        setProgramBytes([0x8d, 0x01, 0x10]) // sta $1001
        setProgramBytes([0xa9, chr("l")])   // lda #'l'
        setProgramBytes([0x8d, 0x02, 0x10]) // sta $1002
        setProgramBytes([0xa9, chr("l")])   // lda #'l'
        setProgramBytes([0x8d, 0x03, 0x10]) // sta $1003
        setProgramBytes([0xa9, chr("o")])   // lda #'o'
        setProgramBytes([0x8d, 0x04, 0x10]) // sta $1004
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
        XCTAssertEqual(regs.a, UInt8(0), "A")
        XCTAssertEqual(regs.status & 0xdf, UInt8(0x02), "S")
    }
    
    func testDecimalADC() {
        setProgramBytes([0xa9, 0x00])       // lda #0
        setProgramBytes([0x48])             // pha
        setProgramBytes([0x28])             // plp
        setProgramBytes([0xf8])             // sed
        setProgramBytes([0x38])             // sec
        setProgramBytes([0xa9, 0x99])       // lda #$99
        setProgramBytes([0x69, 0x99])       // adc #$99
        setProgramBytes([0x8d, 0x02, 0xef]) // sta $ef02
        setProgramBytes([0xdb])             // stp
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.a, UInt8(0x99), "A")
        XCTAssertEqual(regs.status & 0x01, UInt8(0x01), "C")
        XCTAssertEqual(regs.status & 0x02, UInt8(0x00), "Z")
        XCTAssertEqual(regs.status & 0x80, UInt8(0x80), "N")
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
        XCTAssertEqual(regs.a, UInt8(0x98), "A")
        XCTAssertEqual(regs.status | 0x20, UInt8(0xad), "S")
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
        XCTAssertEqual(regs.x, UInt8(0xff), "X")
        XCTAssertEqual(regs.status | 0x20, UInt8(0xa4), "S")
    }
    
    func testBRAForward() {
        setProgramBytes([0x80, 0x7f])       // bra $0481
        for i in 0..<254 {
            setProgramBytes([0xdb])             // stp
        }
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.pc, UInt16(0x1082), "PC")
    }
    
    func testBRABackward() {
        setProgramBytes([0x4c, 0x00, 0x11]) // jmp $0500
        for i in 0..<253 {
            setProgramBytes([0xdb])             // stp
        }
        setProgramBytes([0x80, 0x80])       // bra $0482
        c02emuReset(emuState)
        c02emuRun(emuState)
        let regs = c02emuCPURegs(emuState)
        XCTAssertEqual(regs.pc, UInt16(0x1083), "PC")
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
        XCTAssertEqual(regs.a, UInt8(0xff), "A")
        XCTAssertEqual(regs.status | 0x20, UInt8(0xa4), "S")
    }
    
    func testHCMTest() {
        for test in 0...14 {
            NSLog("Running HCM test \(test)")
            let name = String(format: "hcm-test%02d", test)
            let bundle = NSBundle(forClass: self.dynamicType)
            if let romData = NSData(contentsOfURL: bundle.URLForResource(name, withExtension: "bin")!) {
                c02emuLoadROM(emuState, romData.bytes, UInt(romData.length))
            } else {
                XCTAssertTrue(false, "Couldn't load \(name).bin")
            }
            c02emuReset(emuState)
            if test == 15 {
                c02emuSetCPUTrace(emuState, true)
                c02emuSetRAMTrace(emuState, true)
            }
            while c02emuRun(emuState).value == C02EMU_FRAME_READY.value {
            }
            let regs = c02emuCPURegs(emuState)
            XCTAssertEqual(regs.a, UInt8(0x00), "HCM test \(test) failed")
        }
    }
    
    func test6502FuncTest() {
        var frame = 0
        
        let bundle = NSBundle(forClass: self.dynamicType)
        if let romData = NSData(contentsOfURL: bundle.URLForResource("6502_functional_test", withExtension: "bin")!) {
            loadBin(0x1000, data: romData.bytes, length: romData.length)
        } else {
            XCTAssertTrue(false, "Couldn't load 6502_functional_test.bin")
        }
        c02emuReset(emuState)
        while c02emuRun(emuState).value == C02EMU_FRAME_READY.value {
            //NSLog("Frame: \(frame++)")
        }
    }
    
    func test65C02ExtendedOpcodes() {
        var frame = 0
        
        let bundle = NSBundle(forClass: self.dynamicType)
        if let romData = NSData(contentsOfURL: bundle.URLForResource("65C02_extended_opcodes_test", withExtension: "bin")!) {
            loadBin(0x1000, data: romData.bytes, length: romData.length)
        } else {
            XCTAssertTrue(false, "Couldn't load 65C02_extended_opcodes_test.bin")
        }
        c02emuReset(emuState)
        while c02emuRun(emuState).value == C02EMU_FRAME_READY.value {
            //NSLog("Frame: \(frame++)")
        }
    }
    
    func testBruceClarkBCD() {
        var frame = 0
        
        let bundle = NSBundle(forClass: self.dynamicType)
        if let url = bundle.URLForResource("bcdtest", withExtension: "bin") {
            if let romData = NSData(contentsOfURL: url) {
                c02emuLoadROM(emuState, romData.bytes, UInt(romData.length))
            } else {
                XCTFail("Couldn't read bcdtest.bin")
            }
        } else {
            XCTFail("Couldn't find bcdtest.bin")
        }
        c02emuReset(emuState)
        loop: for ;; {
            switch c02emuRun(emuState).value {
            case C02EMU_FRAME_READY.value:
                continue
            case C02EMU_CPU_STOPPED.value:
                break loop
            default:
                XCTFail("Unexpected return reason")
            }
        }
        let error = Bool(c02emuCPURead(emuState, 0x0200) != 00)
        if error {
            let regs = c02emuCPURegs(emuState)
            if regs.a == 0x41 {
                NSLog(String(format: "%@ ADC #$%02x SBC #$%02x", regs.y == 1 ? "SEC" : "CLC", c02emuCPURead(emuState, 0x0201), c02emuCPURead(emuState, 0x0202)))
            } else {
                NSLog(String(format: "%@ LDA #$%02x SBC #$%02x", regs.y == 1 ? "SEC" : "CLC", c02emuCPURead(emuState, 0x0201), c02emuCPURead(emuState, 0x0202)))
            }
            let DNVZC = c02emuCPURead(emuState, 0x0209)
            let DA = c02emuCPURead(emuState, 0x0208)
            let CF = c02emuCPURead(emuState, 0x0210)
            let ZF = c02emuCPURead(emuState, 0x020f)
            let VF = c02emuCPURead(emuState, 0x020e)
            let NF = c02emuCPURead(emuState, 0x020d)
            let AR = c02emuCPURead(emuState, 0x020c)
            NSLog(String(format: "Expected: %02x %02x %@%@%@%@", AR, ((CF & 1) | (ZF & 2) | (VF & 0x40) | (NF & 0x80)),
                NF & 0x80 != 0 ? "N" : "_",
                VF & 0x40 != 0 ? "V" : "_",
                ZF & 0x02 != 0 ? "Z" : "_",
                CF & 0x01 != 0 ? "C" : "_"))
            NSLog(String(format: "Actual:   %02x %02x %@%@%@%@", DA, DNVZC & 0xc3,
                DNVZC & 0x80 != 0 ? "N" : "_",
                DNVZC & 0x40 != 0 ? "V" : "_",
                DNVZC & 0x02 != 0 ? "Z" : "_",
                DNVZC & 0x01 != 0 ? "C" : "_"))
        }
        XCTAssertEqual(error, false, "BCD test failed")
    }
    
    func testCPUEmulationPerformance() {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let romData = NSData(contentsOfURL: bundle.URLForResource("6502_functional_test", withExtension: "bin")!) {
            loadBin(0x1000, data: romData.bytes, length: romData.length)
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
