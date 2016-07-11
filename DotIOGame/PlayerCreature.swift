//
//  Player.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/10/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class PlayerCreature: SKSpriteNode {
    
    var radius: CGFloat = 50 {
        didSet {
            size.width = 2*radius
            size.height = 2*radius
            zPosition = radius/10 //Big creatures eat up smaller ones in terms of zPosition
        }
    }
    
    var velocity: (speed: CGFloat, angle: CGFloat) = (
        speed: 0,
        angle: 0
        ) {
        didSet {
            // Change positionDeltas to match
            let desiredDx = cos(velocity.angle) * velocity.speed
            let desiredDy = sin(velocity.angle) * velocity.speed
            
            // Only set the position deltas if they have not been set yet (avoiding recursion)
            if positionDeltas.dx != desiredDx {positionDeltas.dx = desiredDx}
            if positionDeltas.dy != desiredDy {positionDeltas.dy = desiredDy}
            
            zRotation = velocity.angle
            
            //print(zRotation)
        }
    }
    
    var positionDeltas: (dx: CGFloat, dy: CGFloat) = (
        dx: 0,
        dy: 0
    )
    
    init(name: String) {
        let texture = SKTexture.init(imageNamed: "red circle.png") //placeholderTexture
        let color = SKColor.whiteColor()
        let size = CGSize(width: 2*radius, height: 2*radius)
        super.init(texture: texture, color: color, size: size)
        radius = 50
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(deltaTime: CFTimeInterval) {
        position.x += positionDeltas.dx * CGFloat(deltaTime)
        position.y += positionDeltas.dy * CGFloat(deltaTime)
    }
    
}
