//
//  Creature.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/15/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class Creature: SKSpriteNode, BoundByCircle {
    // All creatures should eventually extend this class
    var playerID: Int = 0
    var playerColor: Color = .Red
    let textures: [Color: SKTexture] = [
        .Red : SKTexture(imageNamed: "player_red_lit"),
        .Green: SKTexture(imageNamed: "player_green"),
        .Blue: SKTexture(imageNamed: "player_blue_lit"),
        .Yellow: SKTexture(imageNamed: "player_yellow_lit")
    ]
    let orbSpawnUponDeathRadiusMultiplier: CGFloat = 1.5
    var normalSpeed: CGFloat {
        return 30 * pow(1/2, (radius - 50) / 100) + 60
    }
    var boostingSpeed: CGFloat { return normalSpeed * 2.3 }
    var minePropulsionSpeed: CGFloat {
        return radius * 7.1
    }
    var speedDebuffSpeed: CGFloat { return normalSpeed * 3 / 4 }
    
    var currentSpeed: CGFloat = 0 {
        didSet { velocity.speed = currentSpeed }
    }
    
    var velocity: (speed: CGFloat, angle: CGFloat) = (
        speed: 0,
        angle: 0
        ) {
        
        didSet {
            //I want velocity.angle to operate in degrees from 0 to 360
            if velocity.angle > 360 {
                velocity.angle = velocity.angle % 360
            } else if velocity.angle < 0 {
                velocity.angle += 360
            }
            
            // Change positionDeltas to match
            positionDeltas.dx = cos(velocity.angle.degreesToRadians()) * velocity.speed
            positionDeltas.dy = sin(velocity.angle.degreesToRadians()) * velocity.speed
            
//            // Only set the position deltas if they have not been set yet (avoiding recursion)
//            if positionDeltas.dx != desiredDx {positionDeltas.dx = desiredDx}
//            if positionDeltas.dy != desiredDy {positionDeltas.dy = desiredDy}
            
            zRotation = velocity.angle.degreesToRadians()
            
        }
        
    }
    
    var positionDeltas: (dx: CGFloat, dy: CGFloat) = (
        dx: 0,
        dy: 0
    )


    var isBoosting = false
    var spawnMineAtMyTail = false // Set to true in leaveMine. GameScene will repeatedly check leaveMineAtMyTail and will leave a mine if it is true.
    let percentSizeSacrificeToLeaveMine: CGFloat = 0.10 // Constant to be twiddled with
    var mineCoolDownCounter: CGFloat = 4
    
//    var onMineImpulseSpeed: Bool = false
//    var hasSpeedDebuff: Bool = false
    var freshlySpawnedMines: [GoopMine] = []
    
    var minePropulsionSpeedActiveTimeCounter: CGFloat = C.creature_minePropulsionSpeedActiveTime
    var minePropulsionSpeedActiveTimeCounterPreviousValue: CGFloat = C.creature_minePropulsionSpeedActiveTime
    var speedDebuffTimeCounter: CGFloat = C.creature_speedDebuffTime
    var speedDebuffTimeCounterPreviousValue: CGFloat = C.creature_speedDebuffTime
    var onMineImpulseSpeed: Bool { return minePropulsionSpeedActiveTimeCounter < C.creature_minePropulsionSpeedActiveTime }
    var hasSpeedDebuff: Bool { return speedDebuffTimeCounter < C.creature_speedDebuffTime }
    
    var targetAngle: CGFloat! //operates in degrees 0 to 360
    
    var radius: CGFloat = 50 {
        didSet {
            size.width = 2*radius
            size.height = 2*radius
            zPosition = radius/10 //Big creatures eat up smaller ones in terms of zPosition
            //minePropulsionSpeed = radius * 10
        }
    }
    var targetRadius: CGFloat = 50
    var targetArea: CGFloat {
        get {
            return CGFloat(pi) * targetRadius * targetRadius
        }
        set {
            targetRadius = sqrt(newValue / CGFloat(pi))
        }
    }
    
    static let percentGrowAmountToBeDepositedUponDeath: CGFloat = 0.50
    var growAmount: CGFloat { return targetArea }
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat = 50) {
        self.playerID = playerID
        playerColor = color
        let texture = textures[color]
        let color = SKColor.whiteColor()
        let size = CGSize(width: 2*radius, height: 2*radius)
        super.init(texture: texture, color: color, size: size)
        self.currentSpeed = normalSpeed
        defer { //This keyword ensures that the didSet code is called
            velocity.speed = currentSpeed
            velocity.angle = CGFloat.random(min: 0, max: 360)
            targetAngle = velocity.angle
            targetRadius = startRadius
            radius = startRadius
        }
        self.name = name
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        currentSpeed = self.normalSpeed
    }
    
    func update(deltaTime: CFTimeInterval) {
        position.x += positionDeltas.dx * CGFloat(deltaTime)
        position.y += positionDeltas.dy * CGFloat(deltaTime)
        
        // The player's current angle approaches its target angle
        let myAngle = velocity.angle
        var posDist: CGFloat, negDist: CGFloat
        if targetAngle > myAngle {
            posDist = targetAngle - myAngle
            negDist = myAngle + 360 - targetAngle
        } else if targetAngle < myAngle {
            negDist = myAngle - targetAngle
            posDist = 360 - myAngle + targetAngle
        } else {
            negDist = 0
            posDist = 0
        }
        
        var deltaAngle: CGFloat
        if posDist < negDist {
            // Since the positive distance is less than the negative distance, the player will be turned the positive way. The /10's are for smoothness
            deltaAngle = posDist / 10
        } else if negDist < posDist {
            // Since the negative way is shorter, the player will turn the negative way. Again /10 allows smoothness
            deltaAngle = -negDist / 10
        } else {
            //No turning made
            deltaAngle = 0
        }
        
        // cap the angle change per second
        // find the max angle change for this frame based on deltaTime
        // and ensure delta angle is no greater
        let maxAngleChangeThisFrame = C.creature_maxAngleChangePerSecond * CGFloat(deltaTime)
        deltaAngle.clamp(-maxAngleChangeThisFrame, maxAngleChangeThisFrame)
        
        velocity.angle += deltaAngle
        
        //Before having the radius approach the target radius, apply the passive size loss to target radius
        if radius > 50 {
            if isBoosting {
                targetArea -= boostingSizeLoss * CGFloat(deltaTime)
            } else if targetRadius > 80 {
                targetRadius -= passiveSizeLoss * CGFloat(deltaTime)
            }
        }
        
        //Approach targetRadius. So the player can grow the SMOOOOOTH way
        let deltaRadius = targetRadius - radius
        radius += deltaRadius / 10
        
        // Change the speeds if necessary
        //if minePropulsionSpeedActiveTimeCounter < minePropulsionSpeedActiveTime { currentSpeed = minePropulsionSpeed }
        
        if minePropulsionSpeedActiveTimeCounter < C.creature_minePropulsionSpeedActiveTime {
            minePropulsionSpeedActiveTimeCounterPreviousValue = minePropulsionSpeedActiveTimeCounter
            minePropulsionSpeedActiveTimeCounter += CGFloat(deltaTime)
            currentSpeed = minePropulsionSpeed
        } else if minePropulsionSpeedActiveTimeCounter >= C.creature_minePropulsionSpeedActiveTime && minePropulsionSpeedActiveTimeCounterPreviousValue < C.creature_minePropulsionSpeedActiveTime &&
            speedDebuffTimeCounter < C.creature_speedDebuffTime {
            if (speedDebuffTimeCounterPreviousValue == 0) {
                let lookSick = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 0.3, duration: NSTimeInterval(C.creature_speedDebuffTime/4))
                let goBackToNormal = SKAction.colorizeWithColor(UIColor(white: 0, alpha: 0), colorBlendFactor: 0, duration: NSTimeInterval(C.creature_speedDebuffTime/4))
                let speedDebuffVisualIndication = SKAction.sequence([lookSick, SKAction.waitForDuration(NSTimeInterval(C.creature_speedDebuffTime / 4 * 3)), goBackToNormal])
                self.runAction(speedDebuffVisualIndication)
            }
            speedDebuffTimeCounterPreviousValue = speedDebuffTimeCounter
            speedDebuffTimeCounter += CGFloat(deltaTime)
            currentSpeed = speedDebuffSpeed
        } else {
            if isBoosting { currentSpeed = boostingSpeed }
            else { currentSpeed = normalSpeed }
        }
        
        // Mine cooldown
        if mineCoolDownCounter < C.creature_mineCooldownTime {
            mineCoolDownCounter += CGFloat(deltaTime)
        }
        
        // Make sure the player can't boost when "they can't boost"
        if isBoosting && !canBoost {
            stopBoost()
        }
        
        thinkAndAct(CGFloat(deltaTime))
        
    }
    
    func thinkAndAct(deltaTime: CGFloat) {
        // Classes that extend creature can override thinkAndAct() and can change targetAngle
        // boost, and leaveMine()
    }
    
    var passiveSizeLoss: CGFloat { // (per second)
        return CGFloat( 1.25 * pow(2, (radius-30)/100) - 1 )
    }
    
    var boostingSizeLoss: CGFloat { // (per second)
        return targetArea / 20
    }
    
    var canBoost: Bool {
        //return radius > 60
        return true
    }
    
    func startBoost() {
        if !canBoost { return }
        isBoosting = true
        blendMode = SKBlendMode.Add
    }
    
    func stopBoost() {
        isBoosting = false
        blendMode = SKBlendMode.Alpha
    }
    
    func leaveMine() {
        // Firstly, don't allow the leaving of mines if the player is simply too small or if they haven't waited the cooldown time
        if !canLeaveMine { return }
        let waitAction = SKAction.waitForDuration(0.01)
        runAction(waitAction, completion: {
            if self.canLeaveMine { self.spawnMineAtMyTail = true }
            // GameScene will see that this has turned true and spawn the mine for us
            // do the things the player does after leaving a mine
        })
    }
    var canLeaveMine: Bool {
//        return targetRadius * (1-percentSizeSacrificeToLeaveMine) > Creature.minRadius &&
        return mineCoolDownCounter >= C.creature_mineCooldownTime
    }
    
    func mineSpawned() {
        //Called by GameScene after a mine has successfully been spawned at the player's tail
        targetRadius = targetRadius * (1-percentSizeSacrificeToLeaveMine)
        mineCoolDownCounter = 0
        minePropulsionSpeedActiveTimeCounter = 0
        minePropulsionSpeedActiveTimeCounterPreviousValue = 0
        speedDebuffTimeCounter = 0
        speedDebuffTimeCounterPreviousValue = 0
//        let impulseSpeedBump = SKAction.sequence([SKAction.runBlock {
//            self.currentSpeed = self.minePropulsionSpeed
//            }, SKAction.waitForDuration(NSTimeInterval(minePropulsionSpeedActiveTime)), SKAction.runBlock{
//            self.currentSpeed = self.normalSpeed
//            }])
//        self.runAction(impulseSpeedBump, withKey: C.actionkey_leaveMineImpulseSpeedBump, completion: {
//            let speedDebuff = SKAction.sequence([SKAction.runBlock {
//                    self.onMineImpulseSpeed = false
//                    self.hasSpeedDebuff = true
//                    self.currentSpeed = self.speedDebuffSpeed
//                }, SKAction.waitForDuration(NSTimeInterval(C.creature_speedDebuffTime)), SKAction.runBlock {
//                    self.currentSpeed = self.normalSpeed
//                    self.hasSpeedDebuff = false
//                }])
//            self.runAction(speedDebuff, withKey: C.actionkey_leaveMineSpeedDebuff)
//            
//            let lookSick = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 0.3, duration: NSTimeInterval(C.creature_speedDebuffTime/4))
//            let goBackToNormal = SKAction.colorizeWithColor(UIColor(white: 0, alpha: 0), colorBlendFactor: 0, duration: NSTimeInterval(C.creature_speedDebuffTime/4))
//            let speedDebuffVisualIndication = SKAction.sequence([lookSick, SKAction.waitForDuration(NSTimeInterval(C.creature_speedDebuffTime / 4 * 3)), goBackToNormal])
//            self.runAction(speedDebuffVisualIndication)
//        })
    }

    
}