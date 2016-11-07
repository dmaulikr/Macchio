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
        case small, rich, glorious
    }
    
    func seedOrbAtPosition(_ position: CGPoint, growAmount: CGFloat, minRadius: CGFloat, maxRadius: CGFloat, artificiallySpawned: Bool, inColor: Color, asType type: OrbType, growFromNothing: Bool = true) -> EnergyOrb? {
        if let location = convertWorldPointToOrbChunkLocation(position) {
            let newOrb = EnergyOrb(orbColor: inColor, type: type, growFromNothing: growFromNothing)
            newOrb.position = position
            newOrb.growAmount = growAmount
            newOrb.minRadius = minRadius
            newOrb.maxRadius = maxRadius
            newOrb.artificiallySpawned = artificiallySpawned
            orbChunks[location.x][location.y].append(newOrb)
            orbLayer.addChild(newOrb)
            return newOrb
        }
        return nil
    }
    

    
    
    func seedOrbWithSpecifiedType(_ type: OrbType, atPosition position: CGPoint, artificiallySpawned: Bool = false, inColor: Color? = nil, growFromNothing: Bool = true) -> EnergyOrb? {
        let orbColor: Color
        if let _ = inColor { orbColor = inColor! }
        else { orbColor = randomColor() }
        let minRadius = C.orb_minRadii[type]!
        let maxRadius = C.orb_maxRadii[type]!
        let growAmount = C.orb_growAmounts[type]!
        return seedOrbAtPosition(position, growAmount: growAmount, minRadius: minRadius, maxRadius: maxRadius, artificiallySpawned: artificiallySpawned, inColor: orbColor, asType: type, growFromNothing: growFromNothing)
    }

    func seedOrbCluster(ofType type: OrbType, withBudget growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, minRadius: CGFloat = 0, exclusivelyInColor: Color? = nil) {
        let eachOrbGrowAmount = C.orb_growAmounts[type]!
        var budget = growAmount
            
        while budget >= eachOrbGrowAmount {
            let randAngle = CGFloat.random(min: 0, max: 360)
            let randDist = CGFloat.random(min: minRadius, max: radius)
            let randX = aboutPoint.x + (cos(randAngle) * randDist)
            let randY = aboutPoint.y + (sin(randAngle) * randDist)
            let randomSpawnPosition = CGPoint(x: randX, y: randY)
            seedOrbWithSpecifiedType(type, atPosition: randomSpawnPosition, growFromNothing: false)
            
            budget -= eachOrbGrowAmount
        }
    }
    
    func seedOrbClusterFunny(ofType type: OrbType, withBudget growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, minRadius: CGFloat = 0, exclusivelyInColor: Color? = nil) {
        // ** This is an old method. By old, I mean from yesterday and I don't want to use it any more because it results in the orbs having different values and devalues the glorious orb type.
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
        
        func numberOfOrbsAtRadius(_ r: CGFloat) -> Int {
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
        print("Orb grow amount in cluster: \(orbGrowAmount)")
        
        for eachPosition in placeOrbsAtPositions {
            seedOrbAtPosition(eachPosition, growAmount: orbGrowAmount, minRadius: orbMinRadius, maxRadius: orbMaxRadius, artificiallySpawned: true, inColor: orbColor, asType: type)
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
    
    func seedAutoOrbClusterWithBudget(_ growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat, minRadius: CGFloat = 0, exclusivelyInColor: Color? = nil) {
        let maxNumberOfSmallOrbs = 30
        let costToMaxOutSmallOrbs = CGFloat(maxNumberOfSmallOrbs) * C.orb_growAmounts[.small]!
        let orbColor: Color?
        if let exclusivelyInColor = exclusivelyInColor {
            orbColor = exclusivelyInColor
        } else {
            orbColor = nil
        }
        if growAmount < costToMaxOutSmallOrbs {
            seedOrbCluster(ofType: .small, withBudget: growAmount, aboutPoint: aboutPoint, withinRadius: radius, minRadius: minRadius, exclusivelyInColor: orbColor)
        } else {
            seedOrbCluster(ofType: .small, withBudget: costToMaxOutSmallOrbs, aboutPoint: aboutPoint, withinRadius: radius, minRadius: minRadius, exclusivelyInColor: orbColor)
            let richOrbBudget = growAmount - costToMaxOutSmallOrbs
            seedOrbCluster(ofType: .rich, withBudget: richOrbBudget, aboutPoint: aboutPoint, withinRadius: radius, minRadius: minRadius, exclusivelyInColor: orbColor)
        }
        
        orbBeacons.append(OrbBeacon(totalValue: growAmount, radius: radius, position: aboutPoint))
    }
    
    
    func spawnMineAtPosition(_ atPosition: CGPoint, mineRadius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerID: Int) -> Mine {
        let mine = Mine(radius: mineRadius, growAmount: growAmount, color: color, leftByPlayerWithID: leftByPlayerID)
        mine.position = atPosition
        mine.zPosition = 1
        gameWorld.addChild(mine)
        mines.append(mine)
        return mine
    }
    
    func spawnAICreature(atPosition pos: CGPoint = CGPoint(x: 0, y: 0), withRadius radius: CGFloat = C.creature_minRadius) -> Creature {
        let newCreature = AICreature(theGameScene: self, name: computeValidPlayerName(), playerID: randomID(), color: randomColor(), startRadius: radius, rxnTime: CGFloat.random(min: 0.25, max: 0.4))
        newCreature.position = pos
        newCreature.score = Int(CGFloat.random(min: 0, max: 20000))
        //newCreature.velocity.angle = CGFloat.random(min: 0, max: 360) //Don't forget that velocity.angle for creatures operates in degrees
        otherCreatures.append(newCreature)
        gameWorld.addChild(newCreature)
        newCreature.run(SKAction.fadeIn(withDuration: 0.5))
        spawnPlayerNameLabel(forCreature: newCreature)
        return newCreature
    }
    
    func spawnAICreatureAtRandomPosition() {
        let radius = CGFloat.random(min: C.creature_minRadius, max: CGFloat(150))
        spawnAICreature(atPosition: computeValidCreatureSpawnPoint(radius), withRadius: radius)
    }
    
    func spawnPlayerNameLabel(forCreature c: Creature) {
        let newLabel = masterPlayerNameLabel.copy() as! SKLabelNode
        newLabel.text = c.name!
        playerNameLabelsAndCorrespondingIDs.append((label: newLabel, playerID: c.playerID))
        gameWorld.addChild(newLabel)
    }
    
    func computeValidPlayerName(_ attemptNumber: Int = 0) -> String {
        let randName = C.randomPlayerNames.randomItem()
        for c in allCreatures {
            if c.name == randName && c.name != "" && attemptNumber < 10 { return computeValidPlayerName(attemptNumber + 1) }
        }
        return randName
    }
    

}
