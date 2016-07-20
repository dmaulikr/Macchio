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
    var actionQueue: [ActionIdentifier] = []
    var mineTravelDistance: CGFloat { return minePropulsionSpeed * minePropulsionSpeedActiveTime }
    let sniffRange: CGFloat = 500
    let dangerRange: CGFloat = 400
    let leaveMineRange: CGFloat = 300
    let waitingOnMineRange: CGFloat = 400
    
    
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
    
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat, gameScene: GameScene, rxnTime: CGFloat) {
        // The entire game scene is passed in to make the ai creature omniscent.
        // Omniscence is ok for what I'm doing.
        self.gameScene = gameScene
        self.rxnTime = rxnTime
        super.init(name: name, playerID: playerID, color: color, startRadius: startRadius)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func thinkAndAct(deltaTime: CGFloat) {
        switch state {
        case .EatOrbs:
            computeNextEatOrbsAction()
        case .RunningAway:
            computeNextRunningAwayAction()
        case .ChasingSmallerCreature:
            computeNextChasingSmallerCreatureAction()
        case .WaitingOnMine:
            computeNextWaitForMineAction()
        }
        
        rxnTimer += deltaTime
        if rxnTimer >= rxnTime {
            if let nextAction = actionQueue.first {
                actionQueue.removeFirst()
                if nextAction is SetTargetAngleActionIdentifier {
                    self.targetAngle = (nextAction as! SetTargetAngleActionIdentifier).toAngle
                } else if nextAction is ChangeStateActionIdentifier {
                    self.state = (nextAction as! ChangeStateActionIdentifier).toState
                } else if nextAction.type == .StartBoost {
                    startBoost()
                } else if nextAction.type == .StopBoost {
                    stopBoost()
                } else if nextAction.type == .LeaveMine {
                    leaveMine()
                }
            }
            rxnTimer = 0
        }
        
    }
    
    func computeNextEatOrbsAction() {
        if biggerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.RunningAway)
        } else if smallerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.ChasingSmallerCreature)
        } else if let closestMine = findClosestNodeToMeInList(gameScene.goopMines) {
            if closestMine.position.distanceTo(self.position) < waitingOnMineRange {
                state = .WaitingOnMine
                waitingOnMineStateProperties.mine = closestMine as! GoopMine
            }
        } else {
            if let closeOrb = findClosestNodeToMeInList(myChunk) {
                resolveSetTargetAngleTo(angleToNode(closeOrb))
            }
        }
    }
    
    func computeNextChasingSmallerCreatureAction() {
        if biggerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.RunningAway)
        } else if let closestFoodCreature = findClosestNodeToMeInList(smallerCreaturesNearMe) {
            resolveSetTargetAngleTo(angleToNode(closestFoodCreature))
        } else {
            resolveChangeStateTo(.EatOrbs)
        }
    }
    
    func computeNextRunningAwayAction() {
        
        if let closestPredator = findClosestNodeToMeInList(biggerCreaturesNearMe) {
            resolveSetTargetAngleTo( 180 + angleToNode(closestPredator) )
            if position.distanceTo(closestPredator.position) < leaveMineRange && canLeaveMine {
                resolveLeaveMine()
            }
        } else {
            resolveChangeStateTo(.EatOrbs)
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
        
        if let mine = waitingOnMineStateProperties.mine {
            if mine.parent == nil {
                waitingOnMineStateProperties.mine = nil
            } else {
                resolveSetTargetAngleTo(angleToPoint(waitingOnMineStateProperties.stayAtPoint))
            }
        } else if biggerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.RunningAway)
        } else if smallerCreaturesNearMe.count > 0 {
            resolveChangeStateTo(.ChasingSmallerCreature)
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
    
    func actionQueueContainsAsFirstElement(element: ActionIdentifier) -> Bool {
        if let first = actionQueue.first {
            if first.type == .SetTargetAngle && element.type == .SetTargetAngle &&
               fabs((first as! SetTargetAngleActionIdentifier).toAngle - (element as! SetTargetAngleActionIdentifier).toAngle) < 40 {
                return true
            } else if first.type == .ChangeState && element.type == .ChangeState &&
               (first as! ChangeStateActionIdentifier).toState == (element as! ChangeStateActionIdentifier).toState {
                return true
            } else {
                return first.type == element.type
            }
            
        } else {
            return false
        }
    }
    
    func resolveSetTargetAngleTo(angle: CGFloat) {
        let newAction = SetTargetAngleActionIdentifier(toAngle: angle)
        if !actionQueueContainsAsFirstElement(newAction) { actionQueue.append(newAction) }
    }
    
    func resolveChangeStateTo(state: CreatureState) {
        let newAction = ChangeStateActionIdentifier(toState: state)
        if !actionQueueContainsAsFirstElement(newAction) { actionQueue.append(newAction) }
    }
    
    func resolveStartBoost() {
        let newAction = ActionIdentifier(type: .StartBoost)
        if !actionQueueContainsAsFirstElement(newAction) { actionQueue.append(newAction) }
    }
    
    func resolveStopBoost() {
        let newAction = ActionIdentifier(type: .StopBoost)
        if !actionQueueContainsAsFirstElement(newAction) { actionQueue.append(newAction) }
    }
    
    func resolveLeaveMine() {
        let newAction = ActionIdentifier(type: .LeaveMine)
        if !actionQueueContainsAsFirstElement(newAction) { actionQueue.append(newAction) }
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