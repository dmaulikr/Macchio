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
    
    var sectorRatings: [CGFloat] = []
    var sectorContents: [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]] = []
    var anglePerSector: CGFloat {
        return 360.0 / CGFloat(self.sectorRatings.count)
    }
    var shouldBeBoosting: CGFloat = 0 // a value higher than zero means yes, do boost
    var shouldLeaveMine: CGFloat = 0 // a value higher than zero means yes, leave the mine

    
    enum ObjectType {
        case Mine, OrbBeacon, Orb, SmallCreature, LargeCreature, Wall
    }
    
    struct WeightSet {
        let weight_mine: CGFloat
        let weight_orb: CGFloat
        let weight_smallCreature: CGFloat
        let weight_largeCreature: CGFloat
        let weight_moveTowardLargeCreatureJustToGetALittleCloser: CGFloat = 1
        let weight_wall: CGFloat
        
        //Weights be kinda like voting power. + = yes , - = no
        let weight_boostAwayFromLargeCreature: CGFloat = 1
        let weight_boostTowardLargeCreature: CGFloat = -4
        let weight_boostTowardOrb: CGFloat = 0.3
        let bias_boostForNoReason: CGFloat = -2
        
        let weight_leaveMineToAttackPersuingLargeCreature: CGFloat = 2
        let weight_leaveMineToCatchSmallerCreature: CGFloat = 2
        let bias_leaveMineForNoReason: CGFloat = -1
        let leaveMineForPersuingCreatureInRange: CGFloat = 200
    }
    
    // Weights represent how good a type of object is. Higher number means better, negative means it's bad. 
    static let weightSets: [WeightSet] = [
        WeightSet(weight_mine: -5, weight_orb: 0.1, weight_smallCreature: 2, weight_largeCreature: -2, weight_wall: -5) // All around ok
//        WeightSet(weight_mine: 10, weight_orb: -0.5, weight_smallCreature: -4, weight_largeCreature: 10, weight_wall: 5), // Coward
//        WeightSet(weight_mine: 5, weight_orb: -0.5, weight_smallCreature: -8, weight_largeCreature: 9, weight_wall: 8) // Risk-taker / greedy
    ]
    let weightSet: WeightSet = weightSets.randomItem()
    enum WallDirection {
        case Right, Top, Left, Bottom
    }
    
    var mineTravelDistance: CGFloat { return myCreature!.minePropulsionSpeed * C.creature_minePropulsionSpeedActiveTime }

    let numOfSectors = 8
    
    override init(gameScene: GameScene, controlCreature myCreature: AICreature) {
        super.init(gameScene: gameScene, controlCreature: myCreature)
        sectorRatings = [CGFloat](count: numOfSectors, repeatedValue: 0.0)
        sectorContents = [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]](count: numOfSectors, repeatedValue: [] )
    }
    
    override func requestActions() {
        // Basically like an update()
        // Here the action computer should call requestAction() for myCreature to ensure its safety and success
        sectorRatings = [CGFloat](count: numOfSectors, repeatedValue: 0.0)
        sectorContents = [[(objectType: ObjectType, position: CGPoint, radius: CGFloat)]](count: sectorRatings.count, repeatedValue: [])
        shouldBeBoosting = 0
        shouldLeaveMine = 0
        
        if let myCreature = myCreature {
            if let gameScene = myCreature.gameScene {
                
                // Before doing any cool ai stuff, lets update the radar distance to be like something the player would see
                radarDistance = (gameScene.calculateCameraScale(givenPlayerRadius: myCreature.radius, givenMinPlayerRadiusToScreenWidthRatio: C.minPlayerRadiusToScreenWidthRatio, givenMaxPlayerRadiusToScreenWidthRatio: C.maxPlayerRadiusToScreenWidthRatio)) * gameScene.size.width
                
                // First things first, figure out the ideal direction to turn.
                // We do this by assigning numbers to each sector around mycreature and going toward the one with the highest number.
                let minesNearMe = gameScene.mines.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                
                let orbsNearMe = myCreature.myOrbChunk
                
                let allCreaturesNearMe = gameScene.allCreatures.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                let smallCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius * C.percentLargerRadiusACreatureMustBeToEngulfAnother < myCreature.targetRadius }
                let largerCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius > myCreature.targetRadius * C.percentLargerRadiusACreatureMustBeToEngulfAnother }
                var wallsNearMe: [WallDirection] = []
                if myCreature.position.x - radarDistance <= 0 { wallsNearMe.append(.Left) }
                if myCreature.position.x + radarDistance >= gameScene.mapSize.width { wallsNearMe.append(.Right) }
                if myCreature.position.y - radarDistance <= 0 { wallsNearMe.append(.Bottom) }
                if myCreature.position.y + radarDistance >= gameScene.mapSize.height { wallsNearMe.append(.Top) }

                for mine in minesNearMe {
                    assignModifiersForSector(objectPosition: mine.position, objectRadius: mine.radius, weight: weightSet.weight_mine, objectType: .Mine)
                    catalogueObject(atPosition: mine.position, objectRadius: mine.radius, weight: weightSet.weight_mine, objectType: .Mine)
                }
                for orb in orbsNearMe {
                    assignModifiersForSector(objectPosition: orb.position, objectRadius: orb.radius, weight: weightSet.weight_orb, objectType: .Orb)
                    catalogueObject(atPosition: orb.position, objectRadius: orb.radius, weight: weightSet.weight_orb, objectType: .Orb)
                }
                for smallCreature in smallCreaturesNearMe {
                    assignModifiersForSector(objectPosition: smallCreature.position, objectRadius: smallCreature.radius, weight: weightSet.weight_smallCreature, objectType: .SmallCreature)
                    catalogueObject(atPosition: smallCreature.position, objectRadius: smallCreature.radius, weight: weightSet.weight_smallCreature, objectType: .SmallCreature)
                }
                for largeCreature in largerCreaturesNearMe {
                    assignModifiersForSector(objectPosition: largeCreature.position, objectRadius: largeCreature.radius, weight: weightSet.weight_largeCreature, objectType: .LargeCreature)
                    
                    // Also apply the other weight that functions on the distance directly. TODO
                    assignModifiersForSector(objectPosition: largeCreature.position, objectRadius: largeCreature.radius, weight: weightSet.weight_moveTowardLargeCreatureJustToGetALittleCloser, objectType: .LargeCreature, makeModifierFunction: {
                        (distanceAway: CGFloat, weight: CGFloat) in
                        return (distanceAway/self.radarDistance) * weight
                    })
                    

                    
                    catalogueObject(atPosition: largeCreature.position, objectRadius: largeCreature.radius, weight: weightSet.weight_largeCreature, objectType: .LargeCreature)
                    
                }
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
                    assignModifiersForSector(objectPosition: closestPointOnWall, objectRadius: 0, weight: weightSet.weight_wall, objectType: .Wall)
                    catalogueObject(atPosition: closestPointOnWall, objectRadius: 0, weight: weightSet.weight_wall, objectType: .Wall)
                }
                
                var bestIndex = -1
                var bestValue: CGFloat = -9999
                for (index, sectorValue) in sectorRatings.enumerate() {
                    if sectorValue > bestValue {
                        bestValue = sectorValue
                        bestIndex = index
                    }
                }
                
                myCreature.requestAction(AICreature.Action(type: .TurnToAngle, toAngle: CGFloat(bestIndex) * anglePerSector + anglePerSector / 2))
                
                // ***************************************
                // The creature has now done the Turning!
                // Now time to compute if the creature should boost or leave a mine (or both)
                // ***************************************
                
                
                let currentIndex = indexWithinSectorsBounds(Int(myCreature.velocity.angle / anglePerSector))
                let currentIndexAdj1 = indexWithinSectorsBounds(Int(myCreature.velocity.angle / anglePerSector) + 1)
                let currentIndexAdj2 = indexWithinSectorsBounds(Int(myCreature.velocity.angle / anglePerSector) - 1)
                let everythingInFrontOfMe = sectorContents[currentIndex] + sectorContents[currentIndexAdj1] + sectorContents[currentIndexAdj2]

                let opp = currentIndex + sectorRatings.count/2
                let oppositeIndex = indexWithinSectorsBounds(opp)
                let oppositeIndexAdj1 = indexWithinSectorsBounds(opp + 1)
                let oppositeIndexAdj2 = indexWithinSectorsBounds(opp - 1)
                let everythingBehindMe = sectorContents[oppositeIndex] + sectorContents[oppositeIndexAdj1] + sectorContents[oppositeIndexAdj2]
                // Perform deeper analysis
                // Gather all the object identiiers, then make a decision.
                
                let largeCreaturesBehindMe = everythingBehindMe.filter { $0.objectType == .LargeCreature }
                let largeCreaturesInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .LargeCreature }

                let largeCreaturesBehindMeThatCanBeShurikenned = largeCreaturesBehindMe.filter { $0.position.distanceTo(myCreature.position) - $0.radius - myCreature.radius < weightSet.leaveMineForPersuingCreatureInRange }
                
                let smallCreaturesInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .SmallCreature}
                
                let smallCreaturesThatICanCatchByLeavingAMine = smallCreaturesInFrontOfMe.filter { $0.position.distanceTo(myCreature.position) - myCreature.radius < mineTravelDistance }
                
                let orbsInFrontOfMe = everythingInFrontOfMe.filter { $0.objectType == .Orb }
                
                
                // Each weight is kind of like voting power. Some of them are things a player would not ever do. But they still exist as weights, so they have their negative voting power
                shouldBeBoosting += weightSet.bias_boostForNoReason
                for c in largeCreaturesBehindMe{
                    assignModifiersForShouldBeBoosting(objectPosition: c.position, weight: weightSet.weight_boostAwayFromLargeCreature)
                }
                for c in largeCreaturesInFrontOfMe {
                    assignModifiersForShouldBeBoosting(objectPosition: c.position, weight: weightSet.weight_boostTowardLargeCreature)
                }
                for orb in orbsInFrontOfMe {
                    assignModifiersForShouldBeBoosting(objectPosition: orb.position, weight: weightSet.weight_boostTowardOrb)
                }
                
                shouldLeaveMine += weightSet.bias_leaveMineForNoReason
                for _ in smallCreaturesThatICanCatchByLeavingAMine {
                    shouldLeaveMine += weightSet.weight_leaveMineToCatchSmallerCreature
                }
                for _ in largeCreaturesBehindMeThatCanBeShurikenned {
                    shouldLeaveMine += weightSet.weight_leaveMineToAttackPersuingLargeCreature
                }
                
                
                
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
    
    
    func assignModifiersForSector(objectPosition objectPosition: CGPoint, objectRadius: CGFloat, weight: CGFloat, objectType: ObjectType, makeModifierFunction: ((distanceAway: CGFloat, weight: CGFloat) -> CGFloat)? = nil) {
        
        let makeModifier: (distanceAway: CGFloat, weight: CGFloat) -> CGFloat
        if let makeModifierFunction = makeModifierFunction {
            makeModifier = makeModifierFunction
        } else {
            // By default, the weights will increase in strength linearly as they get closer to myCreature
            makeModifier = {
                (distanceAway: CGFloat, weight: CGFloat) in
                return ((self.radarDistance - distanceAway) / self.radarDistance) * weight
            }
        }
        
        let positionRelativeToMyCreature = objectPosition - myCreature!.position
        var angle = positionRelativeToMyCreature.angle.radiansToDegrees()
        if angle < 0 { angle += 360 }
        else if angle > 360 { angle -= 360 }
        let index = Int(angle / anglePerSector)
        //let modifier = ((radarDistance - positionRelativeToMyCreature.length() + objectRadius) / radarDistance) * weight
        let modifier = makeModifier(distanceAway: positionRelativeToMyCreature.length() - objectRadius, weight: weight)
        
        sectorRatings[index] += modifier
        
        sectorRatings[indexWithinSectorsBounds(index + 1)] += modifier / 2
        sectorRatings[indexWithinSectorsBounds(index - 1)] += modifier / 2
        
        let oppositeIndex = index + sectorRatings.count / 2
        sectorRatings[indexWithinSectorsBounds(oppositeIndex)] -= modifier
        sectorRatings[indexWithinSectorsBounds(oppositeIndex + 1)] -= modifier / 2
        sectorRatings[indexWithinSectorsBounds(oppositeIndex - 1)] -= modifier / 2
        
        sectorContents[indexWithinSectorsBounds(index)].append( (objectType: objectType, position: objectPosition, radius: objectRadius) )
    
    }
    
    func catalogueObject(atPosition objectPosition: CGPoint, objectRadius: CGFloat, weight: CGFloat, objectType: ObjectType) {
        let positionRelativeToMyCreature = objectPosition - myCreature!.position
        var angle = positionRelativeToMyCreature.angle.radiansToDegrees()
        if angle < 0 { angle += 360 }
        else if angle > 360 { angle -= 360 }
        let index = Int(angle / anglePerSector)
        sectorContents[indexWithinSectorsBounds(index)].append((objectType: objectType, position: objectPosition, radius: objectRadius))
    }
    
    func indexWithinSectorsBounds(index: Int) -> Int {
        var newIndex = index
        if index < 0 { newIndex += sectorRatings.count }
        else if index >= sectorRatings.count { newIndex -= sectorRatings.count }
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
