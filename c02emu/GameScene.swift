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
    var charAtlas: SKTextureAtlas!
    var emuState: COpaquePointer = nil
    
    override func didMoveToView(view: SKView) {
        self.charAtlas = SKTextureAtlas(named: "Charset")
        self.charTextures = []
        for i in 0..<256 {
            let texture = self.charAtlas.textureNamed(String(format:"char_%03d", i))
            texture.filteringMode = .Nearest
            self.charTextures.append(texture)
        }
        screenCharNodes = []
        for y in 0..<50 {
            for x in 0..<80 {
                let i = (y % 8) * 32 + x % 32
                let sprite = SKSpriteNode(texture: self.charTextures[i])
                sprite.anchorPoint = CGPointZero
                sprite.position = CGPoint(x: x*8, y: 400 - y*8 - 8)
                self.addChild(sprite)
                screenCharNodes.append(sprite)
            }
        }
        
        self.screenCharNodesSetup = true
    }
    
    override func mouseDown(theEvent: NSEvent) {
        let location = theEvent.locationInNode(self)
        NSLog("mouse click location: \(location)")
    }
    
    override func update(currentTime: CFTimeInterval) {
        if self.screenCharNodesSetup {
            let output = c02emuGetOutput(self.emuState)
            for i in 0..<80 * 50 {
                screenCharNodes[i].texture = self.charTextures[Int(output.display.data[i])]
            }
            self.counter++
        }
    }
}
