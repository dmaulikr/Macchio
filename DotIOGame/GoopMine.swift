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
    
    static let shurikenTextures: [Color: SKTexture] = [
        .Red : SKTexture(imageNamed: "shuriken_red"),
        .Green : SKTexture(imageNamed: "shuriken_green"),
        .Blue : SKTexture(imageNamed: "shuriken_blue"),
        .Yellow : SKTexture(imageNamed: "shuriken_yellow")
    ]
    
    var radius: CGFloat = 100 //BS default values
    var growAmount: CGFloat = 100
    let lifeSpan: CGFloat = 4 //Constant to be tweaked
    var lifeCounter: CGFloat = 0
    var rps: CGFloat = 1 // Rotations per second
    var leftByPlayerID: Int = 0

    init(radius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerWithID: Int, rps: CGFloat? = nil) {
        self.radius = radius
        self.growAmount = growAmount
        if let rps = rps { self.rps = rps }
        else {
            self.rps = CGFloat.random(min: 0.3, max: 1)
            if CGFloat.random() > 0.5 { self.rps *= -1 }
        }
        let myTexture = GoopMine.shurikenTextures[color]
        self.leftByPlayerID = leftByPlayerWithID
        super.init(texture: myTexture, color: SKColor.whiteColor(), size: CGSize(width: 2*radius, height: 2*radius))
    }
    
    func belongsToCreature(creature: PlayerCreature) -> Bool {
        return creature.playerID == self.leftByPlayerID
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(deltaTime: CFTimeInterval) {
        lifeCounter += CGFloat(deltaTime)
        zRotation += CGFloat(360 * rps).degreesToRadians() * CGFloat(deltaTime)
    }
    
}