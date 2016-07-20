//
//  Player.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/10/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class PlayerCreature: Creature {
    //TBH, all the player creature really is as of now is a Creature. That's treated specially bty game scene.
    
    override init(name: String, playerID: Int, color: Color, startRadius: CGFloat = 50) {
        super.init(name: name, playerID: playerID, color: color)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
//    override func thinkAndAct(deltaTime: CGFloat) {
//        // Nothing much to do here for player, as the player is controlled by player input
//        //print(targetRadius)
//    }
    
}
