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
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!"
        myLabel.fontSize = 65
        myLabel.fontColor = SKColor.greenColor()
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        
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
        
        self.addChild(myLabel)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        let location = theEvent.locationInNode(self)
        
        NSLog("location: \(location)")
        
        let sprite = SKSpriteNode(imageNamed:"Spaceship")
        sprite.position = location
        sprite.setScale(0.5)
        
        let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
        sprite.runAction(SKAction.repeatActionForever(action))
        
        self.addChild(sprite)
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if self.screenCharNodesSetup {
            for i in 0..<80 * 50 {
                screenCharNodes[i].texture = self.charTextures[(i + self.counter) & 0xff]
            }
            self.counter++
        }
    }
}
