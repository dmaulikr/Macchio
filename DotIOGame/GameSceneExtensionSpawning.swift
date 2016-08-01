//
//  GameSceneExtensionSpawning.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/26/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

extension GameScene {
    
    
    enum OrbType {
        case Small, Rich
    }
    
    
    func seedOrbAtPosition(position: CGPoint, growAmount: CGFloat, minRadius: CGFloat, maxRadius: CGFloat, artificiallySpawned: Bool, inColor: Color, asType type: OrbType) -> EnergyOrb? {
        if let location = convertWorldPointToOrbChunkLocation(position) {
            let newOrb = EnergyOrb(orbColor: inColor, type: type)
            newOrb.position = position
            newOrb.growAmount = growAmount
            newOrb.minRadius = minRadius
            newOrb.maxRadius = maxRadius
            newOrb.artificiallySpawned = artificiallySpawned
            orbChunks[location.x][location.y].append(newOrb)
            addChild(newOrb)
            return newOrb
        }
        return nil
    }
    

    
    
    func seedOrbWithSpecifiedType(type: OrbType, atPosition position: CGPoint, artificiallySpawned: Bool = false, inColor: Color? = nil) -> EnergyOrb? {
        let orbColor: Color
        if let _ = inColor { orbColor = inColor! }
        else { orbColor = randomColor() }
        let minRadius, maxRadius: CGFloat
        let growAmount: CGFloat
        switch type {
        case .Small:
            minRadius = 5
            maxRadius = 7
            growAmount = C.orbGrowAmount[.Small]!
        case .Rich:
            minRadius = 16
            maxRadius = 20
            growAmount = C.orbGrowAmount[.Rich]!
        }
        return seedOrbAtPosition(position, growAmount: growAmount, minRadius: minRadius, maxRadius: maxRadius, artificiallySpawned: artificiallySpawned, inColor: orbColor, asType: type)
    }

    
    func seedSmallOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, exclusivelyInColor: Color? = nil) {
        //Budget is the growAmount quantity that once existed in the entity that spawned the orbs. Mostly, this will be from dead players or old mines.
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrbColor: Color
            if let _ = exclusivelyInColor { newOrbColor = exclusivelyInColor! }
            else { newOrbColor = randomColor() }
            if let newOrb = seedOrbWithSpecifiedType(.Small, atPosition: position, artificiallySpawned: true, inColor: newOrbColor) {
                budget -= newOrb.growAmount
            }
        }
        
    }
    
    func seedRichOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, exclusivelyInColor: Color? = nil) {
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrbColor: Color
            if let _ = exclusivelyInColor { newOrbColor = exclusivelyInColor! }
            else { newOrbColor = randomColor() }
            if let newOrb = seedOrbWithSpecifiedType(.Rich, atPosition: position, artificiallySpawned: true, inColor: newOrbColor) {
                budget -= newOrb.growAmount
            }
        }
        
    }
    
    class OrbBeacon: BoundByCircle {
        var totalValue: CGFloat
        var radius: CGFloat
        var position: CGPoint
        init(totalValue: CGFloat, radius: CGFloat, position: CGPoint) {
            self.totalValue = totalValue
            self.radius = radius
            self.position = position
        }
    }
    
    func seedAutoOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, exclusivelyInColor: Color? = nil) {
        let maxNumberOfSmallOrbs = 30
        let costToMaxOutSmallOrbs = CGFloat(maxNumberOfSmallOrbs) * C.orbGrowAmount[.Small]!
        let orbColor: Color?
        if let exclusivelyInColor = exclusivelyInColor {
            orbColor = exclusivelyInColor
        } else {
            orbColor = nil
        }
        if growAmount < costToMaxOutSmallOrbs {
            seedSmallOrbClusterWithBudget(growAmount, aboutPoint: aboutPoint, withinRadius: radius, exclusivelyInColor: orbColor)
        } else {
            seedSmallOrbClusterWithBudget(costToMaxOutSmallOrbs, aboutPoint: aboutPoint, withinRadius: radius, exclusivelyInColor: orbColor)
            let richOrbBudget = growAmount - costToMaxOutSmallOrbs
            seedRichOrbClusterWithBudget(richOrbBudget, aboutPoint: aboutPoint, withinRadius: radius, exclusivelyInColor: orbColor)
        }
        
        orbBeacons.append(OrbBeacon(totalValue: growAmount, radius: radius, position: aboutPoint))
    }
    
    
    func spawnMineAtPosition(atPosition: CGPoint, mineRadius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerID: Int) -> GoopMine {
        let mine = GoopMine(radius: mineRadius, growAmount: growAmount, color: color, leftByPlayerWithID: leftByPlayerID)
        mine.position = atPosition
        mine.zPosition = 1
        addChild(mine)
        goopMines.append(mine)
        return mine
    }
    
    
    func spawnAICreature() {
        //print("new AI creature spawned")
        //let newCreature = AICreature(theGameScene: self, name: "BS Player Name", playerID: randomID(), color: randomColor(), startRadius: CGFloat.random(min: C.creature_minRadius, max: C.creature_minRadius + 60), rxnTime: CGFloat.random(min: 0.2, max: 0.4))
        
        let newCreature = AICreature(theGameScene: self, name: "player name", playerID: randomID(), color: randomColor(), startRadius: CGFloat.random(min: C.creature_minRadius, max: CGFloat(150)), rxnTime: CGFloat.random(min: 0.35, max: 0.5))
        newCreature.position = computeValidCreatureSpawnPoint(newCreature.radius)
        //newCreature.velocity.angle = CGFloat.random(min: 0, max: 360) //Don't forget that velocity.angle for creatures operates in degrees
        otherCreatures.append(newCreature)
        addChild(newCreature)
        newCreature.runAction(SKAction.fadeInWithDuration(0.5))
    }
    

}
