//
//  Emulator_Tests.swift
//  Emulator Tests
//
//  Created by Pelle on 2015-01-17.
//  Copyright (c) 2015 Per Olofsson. All rights reserved.
//

import Cocoa
import XCTest

class Emulator_Tests: XCTestCase, DisassemblerDelegate {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    var fakeRAM = [UInt8](count: 65536, repeatedValue: 0)
    
    func readMemory(addr: UInt16) -> UInt8 {
        return fakeRAM[Int(addr)]
    }
    
    func testPerformanceExample() {
        let dis = Disassembler(delegate: self)
        arc4random_buf(&fakeRAM, UInt(fakeRAM.count))
        self.measureBlock() {
            let bytes: UInt16 = 0x1000
            dis.disassemble(0xf000)
            while dis.pc &- 0xf000 < bytes {
                dis.disassemble()
            }
        }
    }
    
}
