//
//  WorldControlPanel.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/26/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class WorldControlPanel: NSObject {
    
    let smallOrbGrowAmount: CGFloat = 800
    let richOrbGrowAmount: CGFloat = 2500
    
    func seedOrb(gameScene: GameScene, position: CGPoint, growAmount: CGFloat, minRadius: CGFloat, maxRadius: CGFloat, artificiallySpawned: Bool, inColor: Color) -> EnergyOrb? {
            if let location = gameScene.convertWorldPointToOrbChunkLocation(position) {
                let newOrb = EnergyOrb(orbColor: inColor)
                newOrb.position = position
                newOrb.growAmount = growAmount
                newOrb.minRadius = minRadius
                newOrb.maxRadius = maxRadius
                newOrb.artificiallySpawned = artificiallySpawned
                gameScene.orbChunks[location.x][location.y].append(newOrb)
                gameScene.addChild(newOrb)
                return newOrb
            }
            return nil
    }
    
    func seedSmallOrb(gameScene: GameScene, position: CGPoint, artificiallySpawned: Bool = false, inColor: Color? = nil) -> EnergyOrb? {
        let orbColor: Color
        if let _ = inColor { orbColor = inColor! }
        else { orbColor = randomColor() }
        return seedOrb(gameScene, position: position, growAmount: smallOrbGrowAmount, minRadius: 10, maxRadius: 14, artificiallySpawned: artificiallySpawned, inColor: orbColor)
    }
    
    func seedRichOrb(gameScene: GameScene, position: CGPoint, artificiallySpawned: Bool = false, inColor: Color? = nil) -> EnergyOrb? {
        let orbColor: Color
        if let _ = inColor { orbColor = inColor! }
        else { orbColor = randomColor() }
        return seedOrb(gameScene, position: position, growAmount: richOrbGrowAmount, minRadius: 16, maxRadius: 20, artificiallySpawned: artificiallySpawned, inColor: orbColor)
    }
    
    func seedSmallOrbClusterWithBudget(gameScene: GameScene, growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, exclusivelyInColor: Color? = nil) {
        //Budget is the growAmount quantity that once existed in the entity that spawned the orbs. Mostly, this will be from dead players or old mines.
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrbColor: Color
            if let _ = exclusivelyInColor { newOrbColor = exclusivelyInColor! }
            else { newOrbColor = randomColor() }
            if let newOrb = seedSmallOrb(gameScene, position: position, artificiallySpawned: true, inColor: newOrbColor) {
                budget -= newOrb.growAmount
            }
        }
        
    }
    
    func seedRichOrbClusterWithBudget(gameScene: GameScene, growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, exclusivelyInColor: Color? = nil) {
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrbColor: Color
            if let _ = exclusivelyInColor { newOrbColor = exclusivelyInColor! }
            else { newOrbColor = randomColor() }
            if let newOrb = seedRichOrb(gameScene, position: position, artificiallySpawned: true, inColor: newOrbColor) {
                budget -= newOrb.growAmount
            }
        }
        
    }
    
    func seedAutoOrbClusterWithBudget(gameScene: GameScene, growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, exclusivelyInColor: Color? = nil) {
        let maxNumberOfSmallOrbs = 30
        let costToMaxOutSmallOrbs = CGFloat(maxNumberOfSmallOrbs) * smallOrbGrowAmount
        let orbColor: Color?
        if let exclusivelyInColor = exclusivelyInColor {
            orbColor = exclusivelyInColor
        } else {
            orbColor = nil
        }
        if growAmount < costToMaxOutSmallOrbs {
            seedSmallOrbClusterWithBudget(gameScene, growAmount: growAmount, aboutPoint: aboutPoint, withinRadius: radius, exclusivelyInColor: orbColor)
        } else {
            seedSmallOrbClusterWithBudget(gameScene, growAmount: costToMaxOutSmallOrbs, aboutPoint: aboutPoint, withinRadius: radius, exclusivelyInColor: orbColor)
            let richOrbBudget = growAmount - costToMaxOutSmallOrbs
            seedRichOrbClusterWithBudget(gameScene, growAmount: richOrbBudget, aboutPoint: aboutPoint, withinRadius: radius, exclusivelyInColor: orbColor)
        }
        
        gameScene.orbBeacons.append(OrbBeacon(totalValue: growAmount, radius: radius, position: aboutPoint))
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
    
    
    func spawnMineAtPosition(gameScene: GameScene, atPosition: CGPoint, mineRadius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerID: Int) -> GoopMine {
        let mine = GoopMine(radius: mineRadius, growAmount: growAmount, color: color, leftByPlayerWithID: leftByPlayerID)
        mine.position = atPosition
        mine.zPosition = 1
        gameScene.addChild(mine)
        gameScene.goopMines.append(mine)
        return mine
    }
    
    
    func spawnAICreature(gameScene: GameScene) {
        //print("new AI creature spawned")
        let newCreature = AICreature(name: "BS Player ID", playerID: gameScene.randomID(), color: randomColor(), startRadius: CGFloat.random(min: Creature.minRadius, max: 100), gameScene: gameScene, rxnTime: CGFloat.random(min: 0.2, max: 0.4))
        newCreature.position = gameScene.computeValidCreatureSpawnPoint(newCreature.radius)
        //newCreature.velocity.angle = CGFloat.random(min: 0, max: 360) //Don't forget that velocity.angle for creatures operates in degrees
        gameScene.otherCreatures.append(newCreature)
        gameScene.addChild(newCreature)
        newCreature.runAction(SKAction.fadeInWithDuration(0.5))
    }

}