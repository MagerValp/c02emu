//
//  GameScene.swift
//  c02emu
//
//  Created by Pelle on 2015-01-06.
//  Copyright (c) 2015 University of Gothenburg. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var screenCharNodes: [SKSpriteNode!]!
    var screenCharNodesSetup = false
    var counter = 0
    var charTextures: [SKTexture!]!
    var emuState: COpaquePointer = nil
    
    override func didMoveToView(view: SKView) {
        let charsetImage80x50 = NSImage(named: "Charset-80x50")!
        let charWidth = Int(charsetImage80x50.size.width) / 32
        let charHeight = Int(charsetImage80x50.size.height) / 8
        var charsetProperties80x50 = [String:NSImage]()
        for i in 0..<256 {
            let x = (i % 32) * charWidth
            let y = (7 - i / 32) * charHeight
            let charRect = CGRect(x: x, y: y, width: charWidth, height: charHeight)
            let charImage = NSImage(size: NSSize(width: charWidth, height: charHeight))
            charImage.lockFocus()
            charsetImage80x50.drawAtPoint(NSPoint(x: 0, y: 0), fromRect: charRect, operation: .CompositeCopy, fraction: 1.0)
            charImage.unlockFocus()
            charsetProperties80x50[String(format:"char_%03d", i)] = charImage
        }
        let atlas80x50 = SKTextureAtlas(dictionary: charsetProperties80x50)
        charTextures = []
        for i in 0..<256 {
            let texture = atlas80x50.textureNamed(String(format:"char_%03d", i))
            texture.filteringMode = .Nearest
            charTextures.append(texture)
        }
        screenCharNodes = []
        for y in 0..<50 {
            for x in 0..<80 {
                let i = (y % 8) * 32 + x % 32
                let sprite = SKSpriteNode(texture: charTextures[i])
                sprite.anchorPoint = CGPointZero
                sprite.position = CGPoint(x: x*8, y: 400 - y*8 - 8)
                sprite.size = CGSize(width: 8, height: 8)
                self.addChild(sprite)
                screenCharNodes.append(sprite)
            }
        }
        
        screenCharNodesSetup = true
    }
    
    override func mouseDown(theEvent: NSEvent) {
        let location = theEvent.locationInNode(self)
        NSLog("mouse click location: \(location)")
    }
    
    override func update(currentTime: CFTimeInterval) {
        let reason = c02emuRun(emuState)
        if screenCharNodesSetup {
            let output = c02emuGetOutput(emuState)
            for i in 0..<80 * 50 {
                screenCharNodes[i].texture = charTextures[Int(output.display.data[i])]
            }
            counter++
        }
    }
}
