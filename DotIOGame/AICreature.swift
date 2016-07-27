//
//  AICreature.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/16/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit
import Darwin

class AICreature: Creature {

    // The AI creature is the dumb driver of the ai operation. The action computer is the genius that yells at it to do stuff
    // The AICreature will listen. Somewhat. By adding actions to its pending actions list.
    // The game scene + self + pending actions is a representation of AICreature's DESIRED state. Its other properties and the properties of gameScene represent
    // the CURRENT state. It is the job of the action computer to change the desired state.
    var rxnTime: CGFloat = 0
    var pendingActions: [Action] = []
    var actionComputer: AIActionComputer?
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat, gameScene: GameScene, rxnTime: CGFloat) {
        self.rxnTime = rxnTime
        super.init(name: name, playerID: playerID, color: color, startRadius: startRadius)
        self.actionComputer = AIActionComputer(gameScene: gameScene, controlCreature: self)
    }
    
    override func thinkAndAct(deltaTime: CGFloat) {
        if let actionComputer = actionComputer {
            actionComputer.requestActions()
        }
        
        for action in pendingActions {
            action.effectiveTimer += deltaTime
        }
        let effectiveActions = pendingActions.filter { $0.effectiveTimer >= rxnTime }
        for action in effectiveActions {
            self.executeAction(action)
        }
        pendingActions = pendingActions.filter {
            let pendingAction = $0
            return !effectiveActions.contains { $0 === pendingAction }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    enum ActionType {
        case TurnToAngle, StartBoost, StopBoost, LeaveMine
    }
    
    class Action: NSObject {
        var type: ActionType
        var toAngle: CGFloat? // To angle should be nil when the action is anything other than turn to angle
        var effectiveTimer: CGFloat = 0
        init(type: ActionType, toAngle: CGFloat? = nil) {
            self.type = type
            self.toAngle = toAngle
        }
    }
    
    func executeAction(action: Action) {
        switch action.type {
        case .TurnToAngle:
            if let toAngle = action.toAngle {
                self.targetAngle = toAngle
            }
        case .StartBoost:
            startBoost()
        case .StopBoost:
            stopBoost()
        case .LeaveMine:
            leaveMine()
        }
    }
    
    // To be called by the action computer
    // @ return true if the action was carried out successfully or false if it was ignored.
    // The AI creature decides what it can ignore.
    func requestAction(action: Action) -> Bool {
        // Read the ultimate state variable and see if the requested action is unnecessary. Don't append the action if the ultimate state already accomplishes what would be accomplished by this action.
        // TODO implement
        pendingActions.append(action)
        return true
    }
    
    var ultimateState: (angle: CGFloat, speed: CGFloat, position: CGPoint, isBoosting: Bool, canLeaveMine: Bool, onMineImpulseSpeed: Bool, hasSpeedDebuff: Bool) {
        
        // Initialize a set of variables representing the current conditions
        var angle: CGFloat = self.velocity.angle
        var speed: CGFloat = self.velocity.speed
        var position: CGPoint = self.position
        var isBoosting: Bool = self.isBoosting
        var canLeaveMine: Bool = self.canLeaveMine
        var onMineImpulseSpeed: Bool = self.onMineImpulseSpeed
        var hasSpeedDebuff: Bool = self.hasSpeedDebuff
        
        if pendingActions.count > 0 {
            // Get a list of the pending actions in the order they will happen
            var actionsInOrderOfExecution = pendingActions.sort ({ $0.effectiveTimer > $1.effectiveTimer })
            // Don't forget that the higher the effective timer is, the closer the action is to being completed.
            // The time that the action has to completion = rxnTime - action.effectiveTimer - timePassed (if applicable)
            
            //let actionsInOrderOfExecutioinDummies = (actionsInOrderOfExecution.map { $0.copy() } as! [Action])
            //var turningActions = actionsInOrderOfExecution.filter { $0.type == .TurnToAngle && $0.toAngle != nil }
            
            // Assuming the actions were to all just happen when their effectiveTimers hit the creatures rxn time, assign the variables to compute the ultimate state
            let timeThatWillHavePassed: CGFloat = self.rxnTime - actionsInOrderOfExecution.last!.effectiveTimer
            var timePassed: CGFloat = 0
            var timeUntilReadingNextAction: CGFloat? = actionsInOrderOfExecution.count > 0 ? self.rxnTime - actionsInOrderOfExecution.first!.effectiveTimer : nil
            
            var previousAction: Action? = nil
            for _ in 1...actionsInOrderOfExecution.count {
                if let action = actionsInOrderOfExecution.first {
                    actionsInOrderOfExecution.removeFirst()
                    timePassed = self.rxnTime - action.effectiveTimer
                    
                    // Update important variables
                    if action.type == .StartBoost {
                        speed = boostingSpeed
                        isBoosting = true
                    } else if action.type == .StopBoost {
                        speed = normalSpeed
                        isBoosting = false
                    } else if action.type == .LeaveMine {
                        speed = minePropulsionSpeed
                        canLeaveMine = false
                        onMineImpulseSpeed = true
                    }
                    
                    
                    
                    
                    // Since movement happens all the time and at different speeds, it will be handled here
                    if action.type == .TurnToAngle && action.toAngle != nil {
                        let movementResult = simulateCreatureTurningMovement(startPosition: position, startAngle: angle, targetAngle: action.toAngle!, atSpeed: speed, forDuration: timeUntilReadingNextAction ?? timeThatWillHavePassed - timePassed)
                        position = movementResult.finalPosition
                        angle = movementResult.finalAngle
                    } else {
                         position = simulateCreatureStraightMovement(startPosition: position, startAngle: angle, atSpeed: speed, forDuration: timeUntilReadingNextAction ?? timeThatWillHavePassed - timePassed)
                    }
                    
                    timeUntilReadingNextAction = actionsInOrderOfExecution.first != nil ? self.rxnTime - timePassed - actionsInOrderOfExecution.first!.effectiveTimer : nil // removeFirst() was called at the beginning of the iteration, so now actionsInOrderOfExecution.first! refers to the NEXT action, that will be called in the next iteration, if there is any.
                    previousAction = action
                }
            }
            
            
            
            
            
//            for action in actionsInOrderOfExecution {
//                timePassed = self.rxnTime - action.effectiveTimer
//                if action.type == .TurnToAngle && action.toAngle != nil {
//                    let movementResult = simulateCreatureTurningMovement(startPosition: position, startAngle: angle, targetAngle: action.toAngle!, atSpeed: speed, forTime: timeUntilReadingNextTurnToAngleAction ?? timeThatWillHavePassed - timePassed)
//                    position = movementResult.finalPosition
//                    angle = movementResult.finalAngle
//                    turningActions.removeFirst()
//                    timeUntilReadingNextTurnToAngleAction = turningActions.first != nil ? self.rxnTime - timePassed - turningActions.first!.effectiveTimer : nil
//                } else if action.type == .LeaveMine {
//                    if canLeaveMine && !onMineImpulseSpeed && !hasSpeedDebuff {
//                        
//                    }
//                }
//                
//                // Since movment happens in between all actions, movement can be accounted for in its own block
//                
//            }
        }
        
        return (angle: angle, speed: speed, position: position, isBoosting: isBoosting, canLeaveMine: canLeaveMine, onMineImpulseSpeed: onMineImpulseSpeed, hasSpeedDebuff: hasSpeedDebuff)
        
    }
    
    func simulateCreatureTurningMovement(startPosition startPosition: CGPoint, startAngle: CGFloat, targetAngle: CGFloat, atSpeed creatureSpeed: CGFloat, forDuration timeDuration: CGFloat) -> (finalPosition: CGPoint, finalAngle: CGFloat) {
        
        // Calculate the total delta angle that the simulated creature will take over its journey. Note that all angles here should be degree measures ranging from 0 to 360
        var posDist: CGFloat, negDist: CGFloat
        if targetAngle > startAngle {
            posDist = targetAngle - startAngle
            negDist = startAngle + 360 - targetAngle
        } else if targetAngle < startAngle {
            negDist = startAngle - targetAngle
            posDist = 360 - startAngle + targetAngle
        } else {
            negDist = 0
            posDist = 0
        }
        
        let totalDesiredAngleDelta = posDist > negDist ? posDist : -negDist
        let anIdealAngleChangeRate = totalDesiredAngleDelta / timeDuration // This would be the IDEAL rate; by the time the simulation is finsihed, the creature would be at its target angle. But unfortunately for the creature, there is a turn rate cap.
        let theActualAngleChangeRate = anIdealAngleChangeRate.clamped(0, C.creature_maxAngleChangePerSecond)
        let theActualAngleDelta = theActualAngleChangeRate * timeDuration
        
        let travelDistance = creatureSpeed * timeDuration
        
        // Time to calculate the final x and y coordinates. I could just change the angle all at once, then the distance all at once, but that would be innacurate. The more I split up the calculations, the more accurate the final coordinates get. Split factor can be an arbitrary number.
        let splitFactor = 60
        var finalX = startPosition.x
        var finalY = startPosition.y
        for k in 1...splitFactor {
            finalX += cos((CGFloat(k / splitFactor) * theActualAngleDelta).degreesToRadians()) * travelDistance / CGFloat(splitFactor)
            finalY += sin((CGFloat(k / splitFactor) * theActualAngleDelta).degreesToRadians()) * travelDistance / CGFloat(splitFactor)
        }
        
        let theFinalAngle = theActualAngleChangeRate * timeDuration // We can already predict the final angle based on what we have.
        return (finalPosition: CGPoint(x: finalX, y: finalY), finalAngle: theFinalAngle)
        
    }
    
    func simulateCreatureStraightMovement(startPosition startPosition: CGPoint, startAngle: CGFloat, atSpeed speed: CGFloat, forDuration timeDuration: CGFloat) -> CGPoint {
        // A more efficient function to calculate the creature's final position if they are moving straight
        let travelDistance = speed * timeDuration
        let newX = startPosition.x + cos(startAngle.degreesToRadians()) * travelDistance
        let newY = startPosition.y + sin(startAngle.degreesToRadians()) * travelDistance
        return CGPoint(x: newX, y: newY)
    }
    
}