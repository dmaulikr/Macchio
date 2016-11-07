//
//  Creature.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/15/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Creature: SKSpriteNode, BoundByCircle {
    // A generic creature class!
    var isDead = false // A boolean flag that can be set externally
    var playerID: Int = 0
    var playerColor: Color = .red
    static let textures: [Color: SKTexture] = [
        .red : SKTexture(imageNamed: "player_red_lit"),
        //.Green: SKTexture(imageNamed: "player_green"),
        .blue: SKTexture(imageNamed: "player_blue_lit"),
        .yellow: SKTexture(imageNamed: "player_yellow_lit")
    ]
    var timePlayed: CGFloat = 0
    
    var score: Int = 0
    var scoreFromKills: Int = 0
    var percentScoreFromKills: Double {
        return (Double(scoreFromKills) / Double(score)) * 100.0
    }
    var scoreFromSize: Int = 0
    var timeSinceLastPassiveScoreGain: CGFloat = 0
    var percentScoreFromSize: Double {
        return (Double(scoreFromSize) / Double(score)) * 100.0
    }
    var scoreFromOrbs: Int = 0
    var percentScoreFromOrbs: Double {
        return (Double(scoreFromOrbs) / Double(score)) * 100.0
    }
    
    var normalSpeed: CGFloat { return C.creature_normalSpeed(givenRadius: radius) }
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
                velocity.angle = (velocity.angle).truncatingRemainder(dividingBy: 360)
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
    //var inTheProcessOfLeavingAMine = false
    let percentSizeSacrificeToLeaveMine: CGFloat = 0.10 // Constant to be twiddled with
    var mineCoolDownCounter: CGFloat = C.creature_mineCooldownTime
    var mineCoolDownCounterPreviousValue: CGFloat = C.creature_mineCooldownTime
    
//    var onMineImpulseSpeed: Bool = false
//    var hasSpeedDebuff: Bool = false
    var freshlySpawnedMines: [Mine] = []
    
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
    
    //static let percentGrowAmountToBeDepositedUponDeath: CGFloat = 0.50
    var growAmount: CGFloat { return targetArea }
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat = 50) {
        self.playerID = playerID
        playerColor = color
        let texture = Creature.textures[color]
        let color = SKColor.white
        let size = CGSize(width: 2*radius, height: 2*radius)
        super.init(texture: texture, color: color, size: size)
        self.alpha = 0.9
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
    
    func update(_ deltaTime: CFTimeInterval) {
        position.x += positionDeltas.dx * CGFloat(deltaTime)
        position.y += positionDeltas.dy * CGFloat(deltaTime)
        self.timePlayed += CGFloat(deltaTime)
        
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
                targetRadius -= C.creature_passiveSizeLossPerSecond(givenRadius: self.targetRadius) * CGFloat(deltaTime)
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
                let lookSick = SKAction.colorize(with: SKColor.green, colorBlendFactor: 0.3, duration: TimeInterval(C.creature_speedDebuffTime/4))
                let goBackToNormal = SKAction.colorize(with: UIColor(white: 0, alpha: 0), colorBlendFactor: 0, duration: TimeInterval(C.creature_speedDebuffTime/4))
                let speedDebuffVisualIndication = SKAction.sequence([lookSick, SKAction.wait(forDuration: TimeInterval(C.creature_speedDebuffTime / 4 * 3)), goBackToNormal])
                self.run(speedDebuffVisualIndication)
            }
            speedDebuffTimeCounterPreviousValue = speedDebuffTimeCounter
            speedDebuffTimeCounter += CGFloat(deltaTime)
            currentSpeed = speedDebuffSpeed
        } else {
            if isBoosting { currentSpeed = boostingSpeed }
            else { currentSpeed = normalSpeed }
        }
        
        // Mine cooldown
        mineCoolDownCounterPreviousValue = mineCoolDownCounter
        if mineCoolDownCounter < C.creature_mineCooldownTime {
            mineCoolDownCounter += CGFloat(deltaTime)
        }
        
        // Make sure the player can't boost when "they can't boost"
        if isBoosting && !canBoost {
            stopBoost()
        }
        
        // Award passive score gain
        timeSinceLastPassiveScoreGain += CGFloat(deltaTime)
        let scoreGain = C.creature_passiveScoreIncreasePerSecond(givenRadius: self.targetRadius) * timeSinceLastPassiveScoreGain
        if scoreGain >= 1 {
            //self.score += UInt32(scoreGain)
            self.awardPoints(Int(scoreGain), fromSource: .size)
            timeSinceLastPassiveScoreGain = 0
        }
        
        thinkAndAct(CGFloat(deltaTime))
        
    }
    
    func thinkAndAct(_ deltaTime: CGFloat) {
        // Classes that extend creature can override thinkAndAct() and can change targetAngle
        // boost, and leaveMine()
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
        blendMode = SKBlendMode.add
    }
    
    func stopBoost() {
        isBoosting = false
        blendMode = SKBlendMode.alpha
    }
    let totalPulseTime = 0.2
    func leaveMine() {
        // Firstly, don't allow the leaving of mines if the player is simply too small or if they haven't waited the cooldown time
        if !canLeaveMine { return }
        ///canLeaveMine = false
        mineCoolDownCounter = 0
        // Make the creature pulse
        let expandTime: TimeInterval = 0.20
        let theObjectiveRadius = self.targetRadius * 1.2
        let growRadiusByAmount = theObjectiveRadius - self.targetRadius
        let expandAction = SKAction.customAction(withDuration: expandTime, actionBlock: {
            (node: SKNode, elapsedTime: CGFloat) -> Void in
            let assignRadius = self.targetRadius + (elapsedTime / CGFloat(expandTime))*growRadiusByAmount
            self.size = CGSize(width: assignRadius*2, height: assignRadius*2)
        })
        self.run(expandAction)
        
        let waitForExpandToEnd = SKAction.wait(forDuration: expandTime)
        
        run(waitForExpandToEnd, completion:  {
            if let _ = self.parent { self.spawnMineAtMyTail = true }
        })
    }
    var canLeaveMine: Bool {
//        return targetRadius * (1-percentSizeSacrificeToLeaveMine) > Creature.minRadius &&
        return mineCoolDownCounter >= C.creature_mineCooldownTime
    }
    
    func mineSpawned() {
        //Called by GameScene after a mine has successfully been spawned at the player's tail
        //inTheProcessOfLeavingAMine = false
        
        targetRadius = (targetRadius * (1-percentSizeSacrificeToLeaveMine)).clamped(C.creature_minRadius, C.creature_maxRadius)
        //mineCoolDownCounter = 0
        minePropulsionSpeedActiveTimeCounter = 0
        minePropulsionSpeedActiveTimeCounterPreviousValue = 0
        speedDebuffTimeCounter = 0
        speedDebuffTimeCounterPreviousValue = 0
    }
    
    func awardPoints(_ deltaScore: Int, fromSource: GameScene.PointSource) {
        //Score should be modified from here only
        score += deltaScore
        switch fromSource {
        case .size:
            scoreFromSize += Int(deltaScore)
        case .killsEat, .killsMine:
            scoreFromKills += Int(deltaScore)
        case .orbs:
            scoreFromOrbs += Int(deltaScore)
        }
        
    }
    
}
