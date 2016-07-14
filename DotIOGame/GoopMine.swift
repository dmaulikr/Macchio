//
//  GoopMine.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/13/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class GoopMine: SKSpriteNode, BoundByCircle {
    
    let textureA = SKTexture(imageNamed: "goop_mine_texture_a")
    let textureB = SKTexture(imageNamed: "goop_mine_texture_b")
    
    var radius: CGFloat = 100 //BS default value
    let lifeSpan: CGFloat = 4 //Constant to be tweaked
    var lifeCounter: CGFloat = 0

    init(radius: CGFloat) {
        self.radius = radius
        super.init(texture: textureA, color: SKColor.whiteColor(), size: CGSize(width: 2*radius, height: 2*radius))
        let actionSequence = SKAction.sequence([SKAction.runBlock {
            self.texture = self.textureA
            }, SKAction.waitForDuration(0.1),
            SKAction.runBlock {
                self.texture = self.textureB
            }, SKAction.waitForDuration(0.1)])
        runAction(SKAction.repeatActionForever(actionSequence))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(deltaTime: CFTimeInterval) {
        lifeCounter += CGFloat(deltaTime)
    }
    
}