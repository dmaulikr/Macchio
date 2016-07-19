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
    }
    var state: CreatureState = .EatOrbs
    var mineTravelDistance: CGFloat { return minePropulsionSpeed * minePropulsionSpeedActiveTime }
    let sniffRange: CGFloat = 500
    let dangerRange: CGFloat = 500
    
    var biggerCreaturesNearMe: [Creature] {
        return gameScene.allCreatures.filter { $0 !== self && $0.position.distanceTo(self.position) - $0.radius < dangerRange }
    }
    
    var myChunk: [EnergyOrb] {
        if let myChunkLocation = gameScene.convertWorldPointToOrbChunkLocation(self.position) {
            let myChunk = gameScene.orbChunks[myChunkLocation.x][myChunkLocation.y]
            return myChunk
        }
        return []
    }
    
    
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
        switch state {
        case .EatOrbs:
            performNextEatOrbsAction()
        case .RunningAway:
            performNextRunningAwayAction()
        }
    }
    
    func performNextEatOrbsAction() {
        var closestToMe: (distance: CGFloat, orb: EnergyOrb?) = (distance: gameScene.orbChunkWidth, orb: nil)
        for orb in myChunk {
            let dist = self.position.distanceTo(orb.position)
            if dist < closestToMe.distance {
                closestToMe = (distance: dist, orb: orb)
            }
        }
        if let closeOrb = closestToMe.orb {
            self.targetAngle = angleToNode(closeOrb)
        }
    }
    
    func performNextRunningAwayAction() {
    
    }
    
    override func mineSpawned() {
        // the call back for if a mine was spawned sucessfully
        
        super.mineSpawned()
    }
}