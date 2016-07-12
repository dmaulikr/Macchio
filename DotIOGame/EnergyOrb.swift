//
//  EnergyOrb.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/11/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class EnergyOrb: SKSpriteNode {
    
    var currentRadius = 15
    var minRadius: CGFloat = 15, maxRadius: CGFloat = 20
    var pointValue = 1
    
    init() {
        let texture = SKTexture.init(imageNamed: "blue circle.png")
        let color = SKColor.whiteColor()
        let size = CGSize(width: 2*currentRadius, height: 2*currentRadius)
        super.init(texture: texture, color: color, size: size)
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
