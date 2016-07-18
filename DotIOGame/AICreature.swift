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
    enum CreatureState {
        case EatOrbs
        case RunningAway
        case Hunting
    }
    let sniffRange: CGFloat = 100
    let dangerRange: CGFloat = 100
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat, gameScene: GameScene) {
        // The entire game scene is passed in to make the ai creature omniscent.
        // Omniscence is ok for what I'm doing.
        self.gameScene = gameScene
        super.init(name: name, playerID: playerID, color: color, startRadius: startRadius)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func thinkAndAct() {
        
        if let player = gameScene.player {
            if self.position.distanceTo(player.position) <= sniffRange {
                self.targetAngle = self.angleToNode(player)
            } else {
                performNextRandomAction()
            }
        } else {
            performNextRandomAction()
        }
    }
    
    func performNextRandomAction() {
        if CGFloat.random() > 0.95 {
            self.targetAngle = CGFloat.random(min: 0, max: 360)
        }
        if canLeaveMine {
            leaveMine()
        }
    }
    
    override func mineSpawned() {
        // the call back for if a mine was spawned sucessfully
        
        super.mineSpawned()
    }
}