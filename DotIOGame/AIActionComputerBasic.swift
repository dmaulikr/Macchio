//
//  AIActionComputerBasic.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/28/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class AIActionComputerBasic: AIActionComputer {
    
    enum AIState {
        case EatOrbCluster, RunningAway, Chasing
    }
    var radarDistance: CGFloat = 300
    var state: AIState = .EatOrbCluster
    
    var sectorDangerRatings: [CGFloat] = []
    var sectorContents: [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]] = []
    var anglePerSector: CGFloat {
        return 360.0 / CGFloat(self.sectorDangerRatings.count)
    }
    
    enum ObjectType {
        case Mine, OrbBeacon, SmallCreature, LargeCreature
    }
    
    let weight_mine: CGFloat = 5
    let weight_orbBeacon: CGFloat = -1
    let weight_smallCreature: CGFloat = -2
    let weight_largeCreature: CGFloat = 2
    
    let leaveMineRange: CGFloat = 200
    var mineTravelDistance: CGFloat { return myCreature!.minePropulsionSpeed * C.creature_minePropulsionSpeedActiveTime }

    // TODO add distance fall off weight
    let numOfSectors = 8
    
    override init(gameScene: GameScene, controlCreature myCreature: AICreature) {
        super.init(gameScene: gameScene, controlCreature: myCreature)
        sectorDangerRatings = [CGFloat](count: numOfSectors, repeatedValue: 0.0)
        sectorContents = [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]](count: numOfSectors, repeatedValue: [] )
    }
    
    override func requestActions() {
        // Basically like an update()
        // Here the action computer should call requestAction() for myCreature to ensure its safety and success
        sectorDangerRatings = [CGFloat](count: numOfSectors, repeatedValue: 0.0)
        sectorContents = [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]](count: sectorDangerRatings.count, repeatedValue: [])
        
        if let myCreature = myCreature {
            if let gameScene = myCreature.gameScene {
                //let myCurrentGhost = myCreature.computeUltimateStateAsGhost(myCreature.pendingActions)
                // Establish a danger circle and determine which angle I should request
                
                // Test to find desired sector
                // mines, smaller creatures, larger creatures, orb clusters
                let minesNearMe = gameScene.goopMines.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                let orbBeaconsNearMe = gameScene.orbBeacons.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                
                let allCreaturesNearMe = gameScene.allCreatures.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                let smallCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius * C.percentLargerRadiusACreatureMustBeToEngulfAnother < myCreature.targetRadius }
                let largerCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius > myCreature.targetRadius * C.percentLargerRadiusACreatureMustBeToEngulfAnother }

                for mine in minesNearMe { assignModifiersForSectorAndCatalogueObject(mine.position, objectRadius: mine.radius, weight: weight_mine, objectType: .Mine) }
                for orbBeacon in orbBeaconsNearMe { assignModifiersForSectorAndCatalogueObject(orbBeacon.position, objectRadius: orbBeacon.radius, weight: weight_orbBeacon, objectType: .OrbBeacon) }
                for smallCreature in smallCreaturesNearMe {
                    assignModifiersForSectorAndCatalogueObject(smallCreature.position, objectRadius: smallCreature.radius, weight: weight_smallCreature, objectType: .SmallCreature)
                }
                for largeCreature in largerCreaturesNearMe { assignModifiersForSectorAndCatalogueObject(largeCreature.position, objectRadius: largeCreature.radius, weight: weight_largeCreature, objectType: .LargeCreature) }
                
                var indexWithLeastDanger = -1
                var leastDangerValue: CGFloat = 9999
                for (index, sector) in sectorDangerRatings.enumerate() {
                    if sector < leastDangerValue {
                        leastDangerValue = sector
                        indexWithLeastDanger = index
                    }
                }
                
                myCreature.requestAction(AICreature.Action(type: .TurnToAngle, toAngle: CGFloat(indexWithLeastDanger) * anglePerSector + anglePerSector / 2))
                
                
//                let chosenIndex = indexWithLeastDanger
//                let chosenIndexAdj1 = indexWithinSectorsBounds(indexWithLeastDanger + 1)
//                let chosenIndexAdj2 = indexWithinSectorsBounds(indexWithLeastDanger - 1)
                let currentIndex = indexWithinSectorsBounds(Int(myCreature.velocity.angle / anglePerSector))
                let currentIndexAdj1 = indexWithinSectorsBounds(Int(myCreature.velocity.angle / anglePerSector) + 1)
                let currentIndexAdj2 = indexWithinSectorsBounds(Int(myCreature.velocity.angle / anglePerSector) - 1)
                let everythingInFrontOfMe = sectorContents[currentIndex] + sectorContents[currentIndexAdj1] + sectorContents[currentIndexAdj2]

//                let opp = indexWithLeastDanger + sectorDangerRatings.count/2
                let opp = currentIndex + sectorDangerRatings.count/2
                let oppositeIndex = indexWithinSectorsBounds(opp)
                let oppositeIndexAdj1 = indexWithinSectorsBounds(opp + 1)
                let oppositeIndexAdj2 = indexWithinSectorsBounds(opp - 1)
                let everythingBehindMe = sectorContents[oppositeIndex] + sectorContents[oppositeIndexAdj1] + sectorContents[oppositeIndexAdj2]
                // Perform deeper analysis
                // now I'll figure out why I'm going the direction I am and do something to help myself. Whether that's leaving a mine, starting a boost, or stopping a boost
                var shouldBeBoosting = false
                var shouldLeaveMine = false
                
                let largeCreaturesChasingMe = everythingBehindMe.filter {
                    $0.objectType == .LargeCreature
                }
                let largeCreaturesThatCanBeShurikenned = largerCreaturesNearMe.filter { $0.position.distanceTo(myCreature.position) - $0.radius - myCreature.radius < leaveMineRange }
                
                let smallCreaturesInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .SmallCreature}
                let smallCreaturesThatICanCatchByLeavingAMine = smallCreaturesNearMe.filter { $0.position.distanceTo(myCreature.position) - myCreature.radius < mineTravelDistance }
                
                if largeCreaturesChasingMe.count > 0 || smallCreaturesInFrontOfMe.count > 0 {
                    shouldBeBoosting = true
                }
                
                if largeCreaturesThatCanBeShurikenned.count > 0 || smallCreaturesThatICanCatchByLeavingAMine.count > 0 {
                    shouldLeaveMine = true
                }
                
                if shouldBeBoosting {
                    myCreature.requestAction(AICreature.Action(type: .StartBoost))
                } else {
                    myCreature.requestAction(AICreature.Action(type: .StopBoost))
                }
                
                if shouldLeaveMine {
                    myCreature.requestAction(AICreature.Action(type: .LeaveMine))
                }
                
                
                
            }
            
        }
    }
    
    
    func assignModifiersForSectorAndCatalogueObject(objectPosition: CGPoint, objectRadius: CGFloat, weight: CGFloat, objectType: ObjectType) {
        let positionRelativeToMyCreature = objectPosition - myCreature!.position
        var angle = positionRelativeToMyCreature.angle.radiansToDegrees()
        if angle < 0 { angle += 360 }
        else if angle > 360 { angle -= 360 }
        let index = Int(angle / anglePerSector)
        let modifier = ((radarDistance - positionRelativeToMyCreature.length()) / radarDistance) * weight
        sectorDangerRatings[index] += modifier
        
        sectorDangerRatings[indexWithinSectorsBounds(index + 1)] += modifier / 2
        sectorDangerRatings[indexWithinSectorsBounds(index - 1)] += modifier / 2
        
        let oppositeIndex = index + sectorDangerRatings.count / 2
        sectorDangerRatings[indexWithinSectorsBounds(oppositeIndex)] -= modifier
        sectorDangerRatings[indexWithinSectorsBounds(oppositeIndex + 1)] -= modifier / 2
        sectorDangerRatings[indexWithinSectorsBounds(oppositeIndex - 1)] -= modifier / 2
        
        sectorContents[indexWithinSectorsBounds(index)].append( (objectType: objectType, position: objectPosition, radius: objectRadius) )
    
    }
    
    func indexWithinSectorsBounds(index: Int) -> Int {
        var newIndex = index
        if index < 0 { newIndex += sectorDangerRatings.count }
        else if index >= sectorDangerRatings.count { newIndex -= sectorDangerRatings.count }
        return newIndex
    }
    
    func sectorContentCountOf(forSectorIndex forSectorIndex: Int, lookForType: ObjectType) -> Int {
        let theSectorContent = sectorContents[forSectorIndex]
        var totalFound = 0
        for c in theSectorContent {
            if c.objectType == lookForType { totalFound += 1 }
        }
        return totalFound
    }
    
}