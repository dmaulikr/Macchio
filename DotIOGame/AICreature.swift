//
//  AICreature.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/16/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class AICreature: Creature {
    
    var gameScene: GameScene!
    
    init(name: String, playerID: Int, color: Color, gameScene: GameScene) {
        // The entire game scene is passed in to make the ai creature omniscent.
        // Omniscence is ok for what I'm doing.
        self.gameScene = gameScene
        super.init(name: name, playerID: playerID, color: color)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func thinkAndAct() {
        print("think and act called")
        if let player = gameScene.player {
            self.targetAngle = angleToNode(player)
        }
    }
}