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
    var sectorContents: [[ObjectType]] = []
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
    // TODO add distance fall off weight
    
    override init(gameScene: GameScene, controlCreature myCreature: AICreature) {
        super.init(gameScene: gameScene, controlCreature: myCreature)
        sectorDangerRatings = [CGFloat](count: 8, repeatedValue: 0.0)
        sectorContents = [[ObjectType]](count: sectorDangerRatings.count, repeatedValue: [])
    }
    
    override func requestActions() {
        // Basically like an update()
        // Here the action computer should call requestAction() for myCreature to ensure its safety and success
        sectorDangerRatings = [CGFloat](count: 8, repeatedValue: 0.0)
        sectorContents = [[ObjectType]](count: sectorDangerRatings.count, repeatedValue: [])
        
        if let myCreature = myCreature {
            if let gameScene = myCreature.gameScene {
                //let myCurrentGhost = myCreature.computeUltimateStateAsGhost(myCreature.pendingActions)
                // Establish a danger circle and determine which angle I should request
                
                // Test to find desired sector
                // mines, smaller creatures, larger creatures, orb clusters
                let minesNearMe = gameScene.goopMines.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                let orbBeaconsNearMe = gameScene.orbBeacons.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                
                let allCreaturesNearMe = gameScene.allCreatures.filter { $0.position.distanceTo(myCreature.position) < radarDistance }
                let smallCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius * C.percentLargerACreatureMustBeToEngulfAnother < myCreature.targetRadius }
                let largerCreaturesNearMe = allCreaturesNearMe.filter { $0.targetRadius > myCreature.targetRadius * C.percentLargerACreatureMustBeToEngulfAnother }

                for mine in minesNearMe { assignModifiersForSectorAndCatalogueObject(mine.position, weight: weight_mine, objectType: .Mine) }
                for orbBeacon in orbBeaconsNearMe { assignModifiersForSectorAndCatalogueObject(orbBeacon.position, weight: weight_orbBeacon, objectType: .OrbBeacon) }
                for smallCreature in smallCreaturesNearMe {
                    assignModifiersForSectorAndCatalogueObject(smallCreature.position, weight: weight_smallCreature, objectType: .SmallCreature)
                }
                for largeCreature in largerCreaturesNearMe { assignModifiersForSectorAndCatalogueObject(largeCreature.position, weight: weight_largeCreature, objectType: .LargeCreature) }
                
                var indexWithLeastDanger = -1
                var leastDangerValue: CGFloat = 9999
                for (index, sector) in sectorDangerRatings.enumerate() {
                    if sector < leastDangerValue {
                        leastDangerValue = sector
                        indexWithLeastDanger = index
                    }
                }
                
                myCreature.requestAction(AICreature.Action(type: .TurnToAngle, toAngle: CGFloat(indexWithLeastDanger) * anglePerSector + anglePerSector / 2))
                
                
                let chosenIndex = indexWithLeastDanger
                let chosenIndexAdj1 = indexWithinSectorsBounds(indexWithLeastDanger + 1)
                let chosenIndexAdj2 = indexWithinSectorsBounds(indexWithLeastDanger - 1)

                let opp = indexWithLeastDanger + sectorDangerRatings.count/2
                let oppositeIndex = indexWithinSectorsBounds(opp)
                let oppositeIndexAdj1 = indexWithinSectorsBounds(opp + 1)
                let oppositeIndexAdj2 = indexWithinSectorsBounds(opp - 1)
                // Perform deeper analysis
                // now I'll figure out why I'm going the direction I am and do something to help myself. Whether that's leaving a mine, starting a boost, or stopping a boost
                //var iAmRunningFromALargerCreature = weight_largeCreature > 0 && sectorContentsCountOf(.LargeCreature)
                
                
                
                // Change state
                
            }
            
        }
    }
    
    
    func assignModifiersForSectorAndCatalogueObject(objectPosition: CGPoint, weight: CGFloat, objectType: ObjectType) {
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
        
        sectorContents[indexWithinSectorsBounds(index)].append(objectType)
    
    }
    
    func indexWithinSectorsBounds(index: Int) -> Int {
        var newIndex = index
        if index < 0 { newIndex += sectorDangerRatings.count }
        else if index >= sectorDangerRatings.count { newIndex -= sectorDangerRatings.count }
        return newIndex
    }
    
}