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
        case ChasingSmallerCreature
        case RunningAway
    }
    var state: CreatureState = .EatOrbs
    var mineTravelDistance: CGFloat { return minePropulsionSpeed * minePropulsionSpeedActiveTime }
    let sniffRange: CGFloat = 500
    let dangerRange: CGFloat = 400
    
    var biggerCreaturesNearMe: [Creature] {
        return gameScene.allCreatures.filter { $0 !== self && $0.position.distanceTo(self.position) - $0.radius < dangerRange && $0.radius > self.radius * 1.11 }
    }
    
    var smallerCreaturesNearMe: [Creature] {
        return gameScene.allCreatures.filter { $0 !== self && $0.position.distanceTo(self.position) - $0.radius < sniffRange && $0.radius * 1.11 < self.radius }
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
        case .ChasingSmallerCreature:
            performNextChasingSmallerCreatureAction()
        }
    }
    
    func performNextEatOrbsAction() {
        if biggerCreaturesNearMe.count > 0 {
            state = .RunningAway
        } else if smallerCreaturesNearMe.count > 0 {
            state = .ChasingSmallerCreature
        } else {
            var closestToMe: (distance: CGFloat, orb: EnergyOrb?) = (distance: 99999, orb: nil)
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
    }
    
    func performNextChasingSmallerCreatureAction() {
        var closestToMe: (distance: CGFloat, creature: Creature?) = (distance: 99999, creature: nil)
        for c in smallerCreaturesNearMe {
            let dist = self.position.distanceTo(c.position)
            if dist < closestToMe.distance {
                closestToMe = (distance: dist, creature: c)
            }
        }
        if let closeCreature = closestToMe.creature {
            self.targetAngle = angleToNode(closeCreature)
        }
    }
    
    func performNextRunningAwayAction() {
        
    }
    
    
    override func mineSpawned() {
        // the call back for if a mine was spawned sucessfully
        
        super.mineSpawned()
    }
}