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
    var radarDistance: CGFloat = 500
    var state: AIState = .EatOrbCluster
    
    var sectorDangerRatings: [CGFloat] = []
    var sectorContents: [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]] = []
    var anglePerSector: CGFloat {
        return 360.0 / CGFloat(self.sectorDangerRatings.count)
    }
    var shouldBeBoosting: CGFloat = 0 // a value higher than zero means yes, do boost
    var shouldLeaveMine: CGFloat = 0 // a value higher than zero means yes, leave the mine

    
    enum ObjectType {
        case Mine, OrbBeacon, Orb, SmallCreature, LargeCreature, Wall
    }
    
//    let weight_mine: CGFloat = 5
//    //let weight_orbBeacon: CGFloat = -3
//    let weight_orb: CGFloat = -0.1
//    let weight_smallCreature: CGFloat = -2
//    let weight_largeCreature: CGFloat = 2
//    let weight_wall: CGFloat = 5
    
    struct WeightSet {
        let weight_mine: CGFloat
        let weight_orb: CGFloat
        let weight_smallCreature: CGFloat
        let weight_largeCreature: CGFloat
        let weight_wall: CGFloat
        
        
        //Weights be kinda like voting power
        let weight_boostAwayFromLargeCreature: CGFloat = 1
        let weight_boostTowardLargeCreature: CGFloat = -4
        let weight_boostTowardOrb: CGFloat = 0.1
        let weight_boostForNoReason: CGFloat = -2
        
        let weight_leaveMineToAttackPersuingLargeCreature: CGFloat = -1
        let weight_leaveMineToCatchSmallerCreature: CGFloat = 1
    }
    
    // Weights represent how dangerous a type of object is. Higher number means higher danger, whereas a negative number signifies something good
    static let weightSets: [WeightSet] = [
        WeightSet(weight_mine: 5, weight_orb: -0.1, weight_smallCreature: -2, weight_largeCreature: 2, weight_wall: 5), // All around ok
        WeightSet(weight_mine: 10, weight_orb: -0.5, weight_smallCreature: -4, weight_largeCreature: 10, weight_wall: 5), // Coward
        WeightSet(weight_mine: 5, weight_orb: -0.5, weight_smallCreature: -8, weight_largeCreature: -3, weight_wall: 8) // Risk-taker / greedy
    ]
    let weightSet: WeightSet = weightSets.randomItem()
    enum WallDirection {
        case Right, Top, Left, Bottom
    }
    
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
        shouldBeBoosting = 0
        shouldLeaveMine = 0
        
        if let myCreature = myCreature {
            if let gameScene = myCreature.gameScene {
                //let myCurrentGhost = myCreature.computeUltimateStateAsGhost(myCreature.pendingActions)
                // Establish a danger circle and determine which angle I should request
                
                // Test to find desired sector
                // mines, smaller creatures, larger creatures, orb clusters
                let minesNearMe = gameScene.goopMines.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                //let orbBeaconsNearMe = gameScene.orbBeacons.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                
                let orbsNearMe = myCreature.myOrbChunk
                
                let allCreaturesNearMe = gameScene.allCreatures.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                let smallCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius * C.percentLargerRadiusACreatureMustBeToEngulfAnother < myCreature.targetRadius }
                let largerCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius > myCreature.targetRadius * C.percentLargerRadiusACreatureMustBeToEngulfAnother }
                var wallsNearMe: [WallDirection] = []
                if myCreature.position.x - radarDistance <= 0 { wallsNearMe.append(.Left) }
                if myCreature.position.x + radarDistance >= gameScene.mapSize.width { wallsNearMe.append(.Right) }
                if myCreature.position.y - radarDistance <= 0 { wallsNearMe.append(.Bottom) }
                if myCreature.position.y + radarDistance >= gameScene.mapSize.height { wallsNearMe.append(.Top) }

                for mine in minesNearMe { assignModifiersForSectorAndCatalogueObject(mine.position, objectRadius: mine.radius, weight: weightSet.weight_mine, objectType: .Mine) }
                //for orbBeacon in orbBeaconsNearMe { assignModifiersForSectorAndCatalogueObject(orbBeacon.position, objectRadius: orbBeacon.radius, weight: weight_orbBeacon, objectType: .OrbBeacon) }
                for orb in orbsNearMe { assignModifiersForSectorAndCatalogueObject(orb.position, objectRadius: orb.radius, weight: weightSet.weight_orb, objectType: .Orb) }
                for smallCreature in smallCreaturesNearMe {
                    assignModifiersForSectorAndCatalogueObject(smallCreature.position, objectRadius: smallCreature.radius, weight: weightSet.weight_smallCreature, objectType: .SmallCreature)
                }
                for largeCreature in largerCreaturesNearMe { assignModifiersForSectorAndCatalogueObject(largeCreature.position, objectRadius: largeCreature.radius, weight: weightSet.weight_largeCreature, objectType: .LargeCreature) }
                for wall in wallsNearMe {
                    let closestPointOnWall: CGPoint
                    switch wall {
                    case .Right:
                        closestPointOnWall = CGPoint(x: gameScene.mapSize.width, y: myCreature.position.y)
                    case .Left:
                        closestPointOnWall = CGPoint(x: 0, y: myCreature.position.y)
                    case .Top:
                        closestPointOnWall = CGPoint(x: myCreature.position.x, y: gameScene.mapSize.height)
                    case .Bottom:
                        closestPointOnWall = CGPoint(x: myCreature.position.x, y: 0)
                    }
                    assignModifiersForSectorAndCatalogueObject(closestPointOnWall, objectRadius: 0, weight: weightSet.weight_wall, objectType: .Wall)
                }
                
                var indexWithLeastDanger = -1
                var leastDangerValue: CGFloat = 9999
                for (index, sector) in sectorDangerRatings.enumerate() {
                    if sector < leastDangerValue {
                        leastDangerValue = sector
                        indexWithLeastDanger = index
                    }
                }
                
                myCreature.requestAction(AICreature.Action(type: .TurnToAngle, toAngle: CGFloat(indexWithLeastDanger) * anglePerSector + anglePerSector / 2))
                
                // ***************************************
                // The creature has now done the Turning!
                // Now time to compute if the creature should boost or leave a mine (or both)
                // ***************************************
                
                
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
                // Gather all the object identiiers, then make a decision.
                
                let largeCreaturesBehindMe = everythingBehindMe.filter { $0.objectType == .LargeCreature }
                let largeCreaturesInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .LargeCreature }

                let largeCreaturesBehindMeThatCanBeShurikenned = largerCreaturesNearMe.filter { $0.position.distanceTo(myCreature.position) - $0.radius - myCreature.radius < leaveMineRange }
                
                let smallCreaturesInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .SmallCreature}
                
                let smallCreaturesThatICanCatchByLeavingAMine = smallCreaturesNearMe.filter { $0.position.distanceTo(myCreature.position) - myCreature.radius < mineTravelDistance }
                
                let orbsInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .Orb }
                
                
                // Each weight is kind of like voting power. Some of them are things a player would not ever do. But they still exist as weights, so they have their negative voting power
                shouldBeBoosting += weightSet.weight_boostForNoReason
                for c in largeCreaturesBehindMe{
                    assignModifiersForShouldBeBoosting(objectPosition: c.position, weight: weightSet.weight_boostAwayFromLargeCreature)
                    // TODO actually pass in the closest point to myCreature instead of the center position
                }
                for c in largeCreaturesInFrontOfMe {
                    assignModifiersForShouldBeBoosting(objectPosition: c.position, weight: weightSet.weight_boostTowardLargeCreature)
                }
                for orb in orbsInFrontOfMe {
                    assignModifiersForShouldBeBoosting(objectPosition: orb.position, weight: weightSet.weight_boostTowardOrb)
                }
                
                
                for _ in smallCreaturesThatICanCatchByLeavingAMine {
                    shouldLeaveMine += weightSet.weight_leaveMineToCatchSmallerCreature
                }
                for _ in largeCreaturesBehindMeThatCanBeShurikenned {
                    shouldLeaveMine += weightSet.weight_leaveMineToAttackPersuingLargeCreature
                }
                
//                if largeCreaturesChasingMe.count > 0 || smallCreaturesThatICanCatchByLeavingAMine.count > 0 || orbsInFrontOfMe.count > 10 {
//                    shouldBeBoosting = true
//                }
//                
//                if largeCreaturesThatCanBeShurikenned.count > 0 || smallCreaturesThatICanCatchByLeavingAMine.count > 0 {
//                    shouldLeaveMine = true
//                }
                
                
                if shouldBeBoosting > 0 {
                    myCreature.requestAction(AICreature.Action(type: .StartBoost))
                } else {
                    myCreature.requestAction(AICreature.Action(type: .StopBoost))
                }
                
                if shouldLeaveMine > 0 {
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
    
    func assignModifiersForShouldBeBoosting(objectPosition objectPosition: CGPoint, weight: CGFloat) {
        let modifier = weight * ((radarDistance - myCreature!.position.distanceTo(objectPosition)) / radarDistance)
        shouldBeBoosting += modifier
    }
    
    
}