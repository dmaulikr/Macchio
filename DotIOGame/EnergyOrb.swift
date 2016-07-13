//
//  EnergyOrb.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/11/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class EnergyOrb: SKSpriteNode, BoundByCircle {
    
    var radius: CGFloat = 15 {
        didSet {
            size = CGSize(width: radius * 2, height: radius * 2)
        }
    }
    var minRadius: CGFloat = 10, maxRadius: CGFloat = 15
    var pointValue = 1
    var growAmount: CGFloat { return CGFloat(pointValue) / 5 }
    
    var growing = false
    
    init() {
        let texture = SKTexture.init(imageNamed: "blue circle.png")
        let color = SKColor.whiteColor()
        defer { radius = CGFloat.random(min: minRadius, max: maxRadius) }
        let size = CGSize(width: 2*radius, height: 2*radius)
        super.init(texture: texture, color: color, size: size)
        zPosition = 0
        alpha = 0.5
        blendMode = SKBlendMode.Add
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(deltaTime: CFTimeInterval) {
        if growing {
            radius += 20 * CGFloat(deltaTime)
            if radius >= maxRadius {growing = false}
        } else {
            radius -= 20 * CGFloat(deltaTime)
            if radius <= minRadius {growing = true}
        }
    }
    
    
    
}
