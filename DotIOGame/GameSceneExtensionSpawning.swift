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
        case Small, Rich, Glorious
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
        let minRadius = C.orb_minRadii[type]!
        let maxRadius = C.orb_maxRadii[type]!
        let growAmount = C.orb_growAmounts[type]!
        return seedOrbAtPosition(position, growAmount: growAmount, minRadius: minRadius, maxRadius: maxRadius, artificiallySpawned: artificiallySpawned, inColor: orbColor, asType: type)
    }

    
    func seedOrbCluster(ofType type: OrbType, withBudget growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, minRadius: CGFloat = 0, exclusivelyInColor: Color? = nil) {
        // When an orb cluster is seeded, different "shell" levels are given a finite number of orbs at random angles
        // The result is hopefully something that resembles an orb forest.
        var budget = growAmount
        //let shellIncrement: CGFloat = 45 // The distance between each shell
        
        let orbColor = exclusivelyInColor != nil ? exclusivelyInColor! : randomColor()
        let orbMinRadius: CGFloat = C.orb_minRadii[type]!
        let orbMaxRadius: CGFloat = C.orb_maxRadii[type]!
        //let orbGrowAmount: CGFloat = C.orb_growAmounts[type]!
        // Find the number of orb shells that have to exist if the final spawn radius is to stretch from minRadius to the specified radius
        let numberOfOrbShells = Int(round( (radius - minRadius) / orbMaxRadius ))
        var totalNumOfOrbs: Int = 0 // Represents the total number of orbs I will need to spawn in this entire orb cluster
        
        func numberOfOrbsAtRadius(r: CGFloat) -> Int {
            return Int( (2*pi*r) / ( 2 * orbMaxRadius ) / 2 ) // The / x at the end allows me to tamper w/ number of orbs at level
        }
        var placeOrbsAtPositions: [CGPoint] = []
        var r = minRadius + orbMaxRadius
        // Go through and figure out the number of orbs I'll end up spawning. While I'm at it, I'll also get the positions I'll spawn stuff at
        if numberOfOrbShells > 0 {
            for _ in 0..<numberOfOrbShells {
                // Here's the counting part
                let numOrbsInShell = numberOfOrbsAtRadius(r)
                totalNumOfOrbs += numOrbsInShell
                
                // Now here comes the predetermining orb posititions
                for _ in 0..<numOrbsInShell {
                    let aRandomAngle = CGFloat.random(min: 0, max: 360)
                    let randX = aboutPoint.x + cos(aRandomAngle) * r
                    let randY = aboutPoint.y + sin(aRandomAngle) * r
                    let randomOrbPosition = CGPoint(x: randX, y: randY)
                    placeOrbsAtPositions.append(randomOrbPosition)
                }
                
                r += 2*orbMaxRadius
            }
        }
        let orbGrowAmount: CGFloat = budget / CGFloat(totalNumOfOrbs) // So this way, the budget I'm given is distributed across all the orbs
        
        for eachPosition in placeOrbsAtPositions {
            seedOrbAtPosition(eachPosition, growAmount: orbGrowAmount, minRadius: orbMinRadius, maxRadius: orbMaxRadius, artificiallySpawned: true, inColor: orbColor, asType: type)
        }
        
//        var placeOrbsAtRadius = minRadius + orbMinRadius
//        while budget > 0 {
//            let numOfOrbsToPlaceAtThisRadius: Int = Int((pi * 2*placeOrbsAtRadius) / (2*orbMinRadius))
//            if numOfOrbsToPlaceAtThisRadius > 0 {
//                for _ in 0 ..< numOfOrbsToPlaceAtThisRadius {
//                    budget -= orbGrowAmount
//                    if budget <= 0 { break }
//                    let aRandomAngle = CGFloat.random(min: 0, max: 360)
//                    let randX = aboutPoint.x + cos(aRandomAngle) * placeOrbsAtRadius
//                    let randY = aboutPoint.y + sin(aRandomAngle) * placeOrbsAtRadius
//                    let randomOrbPosition = CGPoint(x: randX, y: randY)
//                    seedOrbAtPosition(randomOrbPosition, growAmount: orbGrowAmount, minRadius: orbMinRadius, maxRadius: orbMaxRadius, artificiallySpawned: true, inColor: orbColor, asType: type)
//                }
//            }
//            placeOrbsAtRadius += orbMaxRadius
//        }

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
    
    func seedAutoOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, minRadius: CGFloat = 0, exclusivelyInColor: Color? = nil) {
        let maxNumberOfSmallOrbs = 30
        let costToMaxOutSmallOrbs = CGFloat(maxNumberOfSmallOrbs) * C.orb_growAmounts[.Small]!
        let orbColor: Color?
        if let exclusivelyInColor = exclusivelyInColor {
            orbColor = exclusivelyInColor
        } else {
            orbColor = nil
        }
        if growAmount < costToMaxOutSmallOrbs {
            seedOrbCluster(ofType: .Small, withBudget: growAmount, aboutPoint: aboutPoint, withinRadius: radius, minRadius: minRadius, exclusivelyInColor: orbColor)
        } else {
            seedOrbCluster(ofType: .Small, withBudget: costToMaxOutSmallOrbs, aboutPoint: aboutPoint, withinRadius: radius, minRadius: minRadius, exclusivelyInColor: orbColor)
            let richOrbBudget = growAmount - costToMaxOutSmallOrbs
            seedOrbCluster(ofType: .Rich, withBudget: richOrbBudget, aboutPoint: aboutPoint, withinRadius: radius, minRadius: minRadius, exclusivelyInColor: orbColor)
        }
        
        orbBeacons.append(OrbBeacon(totalValue: growAmount, radius: radius, position: aboutPoint))
    }
    
    
    func spawnMineAtPosition(atPosition: CGPoint, mineRadius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerID: Int) -> Mine {
        let mine = Mine(radius: mineRadius, growAmount: growAmount, color: color, leftByPlayerWithID: leftByPlayerID)
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
