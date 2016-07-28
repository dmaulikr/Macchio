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
    
    func computeUltimateState(pendingActions: [Action]) -> (angle: CGFloat, speed: CGFloat, position: CGPoint, isBoosting: Bool, mineCooldownCounter: CGFloat, minePropulsionCounter: CGFloat, speedDebuffCounter: CGFloat) {
        
        // Initialize a set of variables representing the current conditions
        var sim_angle: CGFloat = self.velocity.angle
        var sim_targetAngle: CGFloat = self.targetAngle
        var sim_speed: CGFloat = self.velocity.speed
        var sim_position: CGPoint = self.position
        var sim_isBoosting: Bool = self.isBoosting
        var sim_mineCooldownCounter: CGFloat = self.mineCoolDownCounter
        var sim_minePropulsionCounter: CGFloat = self.minePropulsionSpeedActiveTimeCounter
        var sim_speedDebuffCounter: CGFloat = self.speedDebuffTimeCounter
        
        
        if pendingActions.count > 0 {
            let sim_actionsInOrder = pendingActions.sort ({ $0.effectiveTimer > $1.effectiveTimer }).map{ $0.copy() } as! [Action]
            // * since sim_actions in order is just a copy of the actual pending actions, anything can be done with these actions. It won't screw up the actual ones.
            
            var sim_timeElapsed: CGFloat = 0
            for action in sim_actionsInOrder {
                let sim_timeElapsedToCompleteThisAction = self.rxnTime - action.effectiveTimer // The simulated time has passed for THIS current action to have been completed
                sim_timeElapsed += sim_timeElapsedToCompleteThisAction
                for eachAction in sim_actionsInOrder {
                    eachAction.effectiveTimer += sim_timeElapsedToCompleteThisAction
                }
                
                // Update the simulated variables passively
                var timeGivenToMinePropulsionCounter: CGFloat = 0
                if sim_minePropulsionCounter < C.creature_minePropulsionSpeedActiveTime {
                    timeGivenToMinePropulsionCounter = sim_timeElapsedToCompleteThisAction.clamped(0, C.creature_minePropulsionSpeedActiveTime - sim_minePropulsionCounter + 0.00001)
                    sim_minePropulsionCounter += timeGivenToMinePropulsionCounter
                }
                
                if sim_speedDebuffCounter < C.creature_speedDebuffTime {
                    sim_speedDebuffCounter += (sim_timeElapsedToCompleteThisAction - timeGivenToMinePropulsionCounter).clamped(0, C.creature_speedDebuffTime - sim_speedDebuffCounter + 0.00001)
                }
                
                if sim_mineCooldownCounter < C.creature_mineCooldownTime {
                    sim_mineCooldownCounter += sim_timeElapsedToCompleteThisAction.clamped(0, C.creature_mineCooldownTime - sim_mineCooldownCounter + 0.00001)
                }
                
                // Now update the simulated variables based on the action that just happened
                switch action.type {
                case .LeaveMine:
                    if sim_mineCooldownCounter >= C.creature_mineCooldownTime {
                        sim_mineCooldownCounter = 0
                        sim_minePropulsionCounter = 0
                        sim_speedDebuffCounter = 0
                    }
                case .StartBoost:
                    sim_isBoosting = true
                case .StopBoost:
                    sim_isBoosting = false
                case .TurnToAngle:
                    sim_targetAngle = action.toAngle != nil ? action.toAngle! : sim_targetAngle
                }
                
                // Speeds
                if sim_minePropulsionCounter < C.creature_minePropulsionSpeedActiveTime {
                    sim_speed = minePropulsionSpeed
                } else if sim_speedDebuffCounter < C.creature_speedDebuffTime {
                    sim_speed = speedDebuffSpeed
                } else if sim_isBoosting {
                    sim_speed = boostingSpeed
                } else {
                    sim_speed = normalSpeed
                }
                
                // Movement
                if sim_angle == sim_targetAngle {
                    sim_position = simulateCreatureStraightMovement(startPosition: sim_position, startAngle: sim_angle, atSpeed: sim_speed, forDuration: sim_timeElapsedToCompleteThisAction)
                } else {
                    let movementResult = simulateCreatureTurningMovement(startPosition: sim_position, startAngle: sim_angle, targetAngle: sim_targetAngle, atSpeed: sim_speed, forDuration: sim_timeElapsedToCompleteThisAction)
                    sim_position = movementResult.finalPosition
                    sim_angle = movementResult.finalAngle
                }
                
            }

        }
        
        return (angle: sim_angle, speed: sim_speed, position: sim_position, isBoosting: sim_isBoosting, mineCooldownCounter: sim_mineCooldownCounter, minePropulsionCounter: sim_minePropulsionCounter, speedDebuffCounter: sim_speedDebuffCounter)
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