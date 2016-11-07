//
//  WarningSign.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/25/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class WarningSign: SKSpriteNode {
    
    weak var correspondingCreature: Creature?
    var flashRate: CGFloat = 0 // = flashes per second. seconds per flash == 1/flashRate
    var flashCounter: CGFloat = 0
    
    init(creature: Creature) {
        self.correspondingCreature = creature
        //let texture = SKTexture(imageNamed: "warning sign.png")
        let texture = SKTexture(imageNamed: "warning_sign.png")
        let size = CGSize(width: 50, height: 50)
        super.init(texture: texture, color: SKColor.white, size: size)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(_ deltaTime: CGFloat) {
        flashCounter += deltaTime
        if flashCounter >=  1 / (flashRate > 0 ? flashRate : 1) {
            // perform flash action
            self.removeAllActions()
            let flashOn = SKAction.run { self.alpha = 1 }
            //let waitAction = SKAction.waitForDuration(0.5)
            let flashOff = SKAction.run { self.alpha = 0.3 }
            let smallWaitAction = SKAction.wait(forDuration: 0.2)
            
            let flashAction = SKAction.sequence([flashOff, smallWaitAction, flashOn])
            self.run(flashAction)

            flashCounter = 0
        }
    }
}
