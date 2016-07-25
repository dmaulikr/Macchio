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
    
    init(creature: Creature) {
        self.correspondingCreature = creature
        let texture = SKTexture(imageNamed: "warning sign.png")
        let size = CGSize(width: 50, height: 50)
        super.init(texture: texture, color: SKColor.whiteColor(), size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}