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
        case WaitingOnMine
        case GoingToCluster
    }
    var state: CreatureState = .EatOrbs {
        willSet {
            //RESET STATE PROPERTIES
            switch state {
            case .WaitingOnMine:
                waitingOnMineStateProperties.mine = nil
                waitingOnMineStateProperties.stayAtPoint = nil
            default:
                break
            }
        }
    }
    var rxnTimer: CGFloat = 0
    var rxnTime: CGFloat = 0
    //var actionQueue: [ActionIdentifier] = []
    var nextTurnAction: SetTargetAngleActionIdentifier? = nil // used exclusively for turn actions
    var buttonActionQueue: [ActionIdentifier] = [] // used exclusively for button related actions (start boost, stop boost, leave mine )
    var mineTravelDistance: CGFloat { return minePropulsionSpeed * minePropulsionSpeedActiveTime }
    
    static let sniffRange: CGFloat = 500
    static let dangerRange: CGFloat = 400
    static let leaveMineRange: CGFloat = 300
    static let waitingOnMineRange: CGFloat = 400
    static let probeDistance: CGFloat = 20
    static let goToBeaconRange: CGFloat = 750

    
    var biggerCreaturesNearMe: [Creature] {
        return gameScene.allCreatures.filter { $0 !== self && $0.position.distanceTo(self.position) - $0.radius < AICreature.dangerRange && $0.radius > self.radius * 1.11 }
    }
    
    var smallerCreaturesNearMe: [Creature] {
        return gameScene.allCreatures.filter { $0 !== self && $0.position.distanceTo(self.position) - $0.radius < AICreature.sniffRange && $0.radius * 1.11 < self.radius }
    }
    
    var myChunk: [EnergyOrb] {
        if let myChunkLocation = gameScene.convertWorldPointToOrbChunkLocation(self.position) {
            let myChunk = gameScene.orbChunks[myChunkLocation.x][myChunkLocation.y]
            return myChunk
        }
        return []
    }
    
    class CollisionProbe: BoundByCircle {
        weak var aicreature: AICreature?
        var radius: CGFloat {
            return aicreature?.radius ?? 0
        }
        var position: CGPoint {
            return aicreature?.probeWorldPositionBasedOnAICreature ?? CGPoint(x: 0, y: 0)
        }
        func setUpProbe(aiCreature: AICreature) {
            self.aicreature = aiCreature
        }
    }
    var collisionProbe: CollisionProbe
    var minesDetectedByProbe: [GoopMine] {
        print("mines detected by probe called")
        var mines: [GoopMine] = []
        for mine in gameScene.goopMines {
            if mine.overlappingCircle(collisionProbe) { mines.append(mine) }
        }
        return mines
    }
    var probeDetectingWall: Bool {
//        return collisionProbe.position.x + collisionProbe.radius >= gameScene.mapSize.width ||
//               collisionProbe.position.x - collisionProbe.radius <= 0 ||
//               collisionProbe.position.y + collisionProbe.radius >= gameScene.mapSize.height ||
//               collisionProbe.position.y - collisionProbe.radius <= 0
        return false
    }
    var probeWorldPositionBasedOnAICreature: CGPoint {
        let probeX = self.position.x  + cos(targetAngle.degreesToRadians()) * (AICreature.probeDistance + 2 * radius)
        let probeY = self.position.y + sin(targetAngle.degreesToRadians()) * (AICreature.probeDistance + 2 * radius)
        return CGPoint(x: probeX, y: probeY)
    }
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat, gameScene: GameScene, rxnTime: CGFloat) {
        // The entire game scene is passed in to make the ai creature omniscent.
        // Omniscence is ok for what I'm doing.
        self.gameScene = gameScene
        self.rxnTime = rxnTime
        collisionProbe = CollisionProbe()
        super.init(name: name, playerID: playerID, color: color, startRadius: startRadius)
        collisionProbe.setUpProbe(self)

    }
    
    required init?(coder aDecoder: NSCoder) {
        collisionProbe = CollisionProbe()
        super.init(coder: aDecoder)
        collisionProbe.setUpProbe(self)
    }
    
    override func thinkAndAct(deltaTime: CGFloat) {
//        print ("think and act called")
        switch state {
        case .EatOrbs:
            computeNextEatOrbsAction()
        case .RunningAway:
            computeNextRunningAwayAction()
        case .ChasingSmallerCreature:
            computeNextChasingSmallerCreatureAction()
        case .WaitingOnMine:
            computeNextWaitForMineAction()
        case .GoingToCluster:
            computeNextGoingToClusterAction()
        }
        
        rxnTimer += deltaTime
        if rxnTimer >= rxnTime {
            if let nextButtonAction = buttonActionQueue.first {
                buttonActionQueue.removeFirst()
                if nextButtonAction.type == .StartBoost {
                    startBoost()
                } else if nextButtonAction.type == .StopBoost {
                    stopBoost()
                } else if nextButtonAction.type == .LeaveMine {
                    leaveMine()
                }
            }
            
            if let turnAction = nextTurnAction {
                self.nextTurnAction = nil
                targetAngle = turnAction.toAngle
//                print("read turn action and executed a turn")
            }
                
                
            rxnTimer = 0
        }
    }
    
    func computeNextEatOrbsAction() {
//        print("ai computing next eat orbs action")
        if isBoosting { resolveStopBoost() }
        
        if minesDetectedByProbe.count > 0 || probeDetectingWall{
            evadeMinesAndWall(minesDetectedByProbe)
        } else if biggerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.RunningAway)
        } else if let _ = closestOrbBeacon {
            resolveChangeStateTo(.GoingToCluster)
        } else if smallerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.ChasingSmallerCreature)
        } else if let closestMine = findClosestNodeToMeInList(gameScene.goopMines) {
            if collisionProbe.overlappingCircle(closestMine as! GoopMine) && closestMine.position.distanceTo(self.position) < AICreature.waitingOnMineRange {
                state = .WaitingOnMine
                waitingOnMineStateProperties.mine = closestMine as! GoopMine
            }
        } else {
            if let closeOrb = findClosestNodeToMeInList(myChunk) {
                print("resolving to change angle to nearest orb")
                resolveSetTargetAngleTo(angleToNode(closeOrb))
            }
        }
    }
    
    func computeNextChasingSmallerCreatureAction() {
        if minesDetectedByProbe.count > 0 || probeDetectingWall {
            if isBoosting { resolveStopBoost() }
            evadeMinesAndWall(minesDetectedByProbe)
        } else if biggerCreaturesNearMe.count > 0 {
            //if !isBoosting && canBoost { resolveStartBoost() }
            resolveChangeStateTo(.RunningAway)
        } else if let closestOrbBeacon = closestOrbBeacon {
            resolveChangeStateTo(.GoingToCluster)
        } else if let closestFoodCreature = findClosestNodeToMeInList(smallerCreaturesNearMe) {
            if !isBoosting && canBoost { resolveStartBoost() }
            else if isBoosting && canLeaveMine && position.distanceTo(closestFoodCreature.position) < mineTravelDistance {
                resolveLeaveMine()
            }
            resolveSetTargetAngleTo(angleToNode(closestFoodCreature))
        } else {
            resolveChangeStateTo(.EatOrbs)
        }
    }
    
    func computeNextRunningAwayAction() {
        if minesDetectedByProbe.count > 0 || probeDetectingWall{
            if isBoosting { resolveStopBoost() }
            evadeMinesAndWall(minesDetectedByProbe)
        } else if biggerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.RunningAway)
        } else if let closestPredator = findClosestNodeToMeInList(biggerCreaturesNearMe) {
            if !isBoosting && canBoost { resolveStartBoost() }
            resolveSetTargetAngleTo( 180 + angleToNode(closestPredator) )
            if position.distanceTo(closestPredator.position) < AICreature.leaveMineRange && canLeaveMine {
                resolveLeaveMine()
            }
        } else {
            resolveChangeStateTo(.EatOrbs)
        }
        
    }
    
    var closestOrbBeacon: GameScene.OrbBeacon? {
        var nearbyBeacon: GameScene.OrbBeacon?
        for b in gameScene.orbBeacons {
            if let _ = nearbyBeacon {
                if b.position.distanceTo(self.position) < nearbyBeacon!.position.distanceTo(self.position) {
                    nearbyBeacon = b
                }
            } else {
                nearbyBeacon = b
            }
        }
        return nearbyBeacon
    }
    func computeNextGoingToClusterAction() {
        if !isBoosting && canBoost { startBoost() }
        if minesDetectedByProbe.count > 0 || probeDetectingWall {
            if isBoosting { resolveStopBoost() }
            evadeMinesAndWall(minesDetectedByProbe)
        } else if let nearestBeacon = closestOrbBeacon {
            resolveSetTargetAngleTo(angleToPoint(nearestBeacon.position))
            if self.overlappingCircle(nearestBeacon) { resolveChangeStateTo(.EatOrbs) }
        } else {
            if isBoosting { resolveStopBoost() }
            resolveChangeStateTo(.EatOrbs)
        }
    }
    
    func evadeMinesAndWall(minesInProbe: [GoopMine]) {
        // Using the information from collision probe, make the player turn the right direction to avoid mines. Or a wall.
        while minesDetectedByProbe.count > 0 {
            var closest: GoopMine?
            for eachMine in minesInProbe {
                if let closeOne = closest {
                    if collisionProbe.position.distanceTo(eachMine.position) < collisionProbe.position.distanceTo(closeOne.position) {
                        closest = eachMine
                    }
                } else {
                    closest = eachMine
                }
            }
            if let closest = closest {
                if self.angleToPoint(closest.position) > self.angleToPoint(collisionProbe.position) {
                    resolveSetTargetAngleTo(self.targetAngle - 90)
                } else {
                    resolveSetTargetAngleTo(self.targetAngle + 90)
                }
            }
        }
        
    }
    
    var waitingOnMineStateProperties: (mine: GoopMine?, stayAtPoint: CGPoint!) = (
        mine: nil,
        stayAtPoint: nil
    )
    func computeNextWaitForMineAction() {
        if waitingOnMineStateProperties.mine == nil {
            let closest: GoopMine? = findClosestNodeToMeInList(gameScene.goopMines) as? GoopMine
            if let closest = closest {
                waitingOnMineStateProperties.mine = closest
            }
        }
        if waitingOnMineStateProperties.stayAtPoint == nil {
            waitingOnMineStateProperties.stayAtPoint = self.position
        }
        
        if let _ = closestOrbBeacon {
            resolveChangeStateTo(.GoingToCluster)
        } else if biggerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.RunningAway)
        } else if smallerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.ChasingSmallerCreature)
        } else if let mine = waitingOnMineStateProperties.mine {
            if mine.parent == nil {
                waitingOnMineStateProperties.mine = nil
                resolveChangeStateTo(.EatOrbs)
            } else {
                resolveSetTargetAngleTo(angleToPoint(waitingOnMineStateProperties.stayAtPoint))
                if minesDetectedByProbe.count > 0 || probeDetectingWall { evadeMinesAndWall(minesDetectedByProbe) }
            }
        } else {
            resolveChangeStateTo(.EatOrbs)
        }
    }
    
    func findClosestNodeToMeInList(nodes: [SKNode]) -> SKNode? {
        var closestToMe: (distance: CGFloat, node: SKNode?) = (distance: 99999, node: nil)
        for thing in nodes {
            let dist = self.position.distanceTo(thing.position)
            if dist < closestToMe.distance {
                closestToMe = (distance: dist, node: thing)
            }
        }
        return closestToMe.node
    }
    
//    func actionQueueContainsAsFirstElement(element: ActionIdentifier) -> Bool {
//        if let first = actionQueue.first {
//            if first.type == .SetTargetAngle && element.type == .SetTargetAngle &&
//               fabs((first as! SetTargetAngleActionIdentifier).toAngle - (element as! SetTargetAngleActionIdentifier).toAngle) < 40 {
//                return true
//            } else if first.type == .ChangeState && element.type == .ChangeState &&
//               (first as! ChangeStateActionIdentifier).toState == (element as! ChangeStateActionIdentifier).toState {
//                return true
//            } else {
//                return first.type == element.type
//            }
//            
//        } else {
//            return false
//        }
//    }
    
    func resolveSetTargetAngleTo(angle: CGFloat) {
        let newAction = SetTargetAngleActionIdentifier(toAngle: angle)
        nextTurnAction = newAction
    }
    
    func resolveChangeStateTo(state: CreatureState) {
        self.state = state
    }
    
    func resolveStartBoost() {
        let newAction = ActionIdentifier(type: .StartBoost)
        buttonActionQueue.append(newAction)
    }
    
    func resolveStopBoost() {
        let newAction = ActionIdentifier(type: .StopBoost)
        buttonActionQueue.append(newAction)
    }
    
    func resolveLeaveMine() {
        let newAction = ActionIdentifier(type: .LeaveMine)
        buttonActionQueue.append(newAction)
    }
    
    enum ActionType {
        case SetTargetAngle
        case ChangeState
        case StartBoost
        case StopBoost
        case LeaveMine
    }
    class ActionIdentifier: NSObject {
        var type: ActionType
        init(type: ActionType) {
            self.type = type
        }
    }
    class SetTargetAngleActionIdentifier: ActionIdentifier {
        var toAngle: CGFloat
        init(toAngle: CGFloat) {
            self.toAngle = toAngle
            super.init(type: .SetTargetAngle)
        }
    }
    
    class ChangeStateActionIdentifier: ActionIdentifier {
        var toState: CreatureState
        init(toState: CreatureState) {
            self.toState = toState
            super.init(type: .ChangeState)
        }
    }
    
    func angleToNode(node: SKNode) -> CGFloat {
        return mapRadiansToDegrees0to360((node.position - self.position).angle)
    }
    
    func angleToPoint(point: CGPoint) -> CGFloat {
        return mapRadiansToDegrees0to360((point - self.position).angle)
    }
    
}