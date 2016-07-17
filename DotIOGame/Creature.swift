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
        .Red : SKTexture(imageNamed: "player_red"),
        .Green: SKTexture(imageNamed: "player_green"),
        .Blue: SKTexture(imageNamed: "player_blue"),
        .Yellow: SKTexture(imageNamed: "player_yellow")
    ]
    
    var normalSpeed: CGFloat = 100
    var boostingSpeed: CGFloat { return normalSpeed * 2 }
    var minePropulsionSpeed: CGFloat = 500
    
    var currentSpeed: CGFloat = 100 {
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
            let desiredDx = cos(velocity.angle.degreesToRadians()) * velocity.speed
            let desiredDy = sin(velocity.angle.degreesToRadians()) * velocity.speed
            
            // Only set the position deltas if they have not been set yet (avoiding recursion)
            if positionDeltas.dx != desiredDx {positionDeltas.dx = desiredDx}
            if positionDeltas.dy != desiredDy {positionDeltas.dy = desiredDy}
            
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
    let mineCoolDown: CGFloat = 4
    var mineCoolDownCounter: CGFloat = 4
    let minePropulsionSpeedActiveTime: CGFloat = 0.25
    var minePropulsionSpeedActiveTimeCounter: CGFloat = 0.25 // Start the mine counter complete
    var freshlySpawnedMine: GoopMine? = nil
    
    let playerMaxAngleChangePerSecond: CGFloat = 180
    
    var targetAngle: CGFloat! //operates in degrees 0 to 360
    
    let minRadius: CGFloat = 50
    var radius: CGFloat = 50 {
        didSet {
            size.width = 2*radius
            size.height = 2*radius
            zPosition = radius/10 //Big creatures eat up smaller ones in terms of zPosition
            minePropulsionSpeed = radius * 10
        }
    }
    var targetRadius: CGFloat = 50
    
    init(name: String, playerID: Int, color: Color, startRadius: CGFloat = 50) {
        self.playerID = playerID
        playerColor = color
        let texture = textures[color]
        let color = SKColor.whiteColor()
        let size = CGSize(width: 2*radius, height: 2*radius)
        super.init(texture: texture, color: color, size: size)
        
        defer { //This keyword ensures that the didSet code is called
            velocity.speed = currentSpeed
            targetRadius = startRadius
            radius = startRadius
        }
        targetAngle = velocity.angle
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        
        // cap with slew rate
        // find the max angle change for this frame based on deltaTime
        // and ensure delta angle is no greater
        let maxAngleChangeThisFrame = playerMaxAngleChangePerSecond * CGFloat(deltaTime)
        deltaAngle.clamp(-maxAngleChangeThisFrame, maxAngleChangeThisFrame)
        
        velocity.angle += deltaAngle
        
        //Before having the radius approach the target radius, apply the passive size loss to target radius
        if !(radius <= 80) { targetRadius -= passiveSizeLoss * CGFloat(deltaTime) }
        
        //Approach targetRadius. So the player can grow the SMOOOOOTH way
        let deltaRadius = targetRadius - radius
        radius += deltaRadius / 10
        
        // Change the speeds if necessary
        if minePropulsionSpeedActiveTimeCounter < minePropulsionSpeedActiveTime { currentSpeed = minePropulsionSpeed }
        else if isBoosting { currentSpeed = boostingSpeed }
        else { currentSpeed = normalSpeed }
        
        // Mine cooldown
        if mineCoolDownCounter < mineCoolDown {
            mineCoolDownCounter += CGFloat(deltaTime)
        }
        
        // Mine propulsion speed counter
        if minePropulsionSpeedActiveTimeCounter < minePropulsionSpeedActiveTime {
            minePropulsionSpeedActiveTimeCounter += CGFloat(deltaTime)
        }
        
        thinkAndAct()
        
    }
    
    func thinkAndAct() {
        // Classes that extend creature can override thinkAndAct() and can change targetAngle
        // boost, and leaveMine()
    }
    
    var passiveSizeLoss: CGFloat {
        return CGFloat(pow(2, (radius - 50) / 75)) / 10
    }
    
    func startBoost() {
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
        spawnMineAtMyTail = true // GameScene will see that this has turned true and spawn the mine for us
        // do the things the player does after leaving a mine
        
    }
    var canLeaveMine: Bool { return targetRadius * (1-percentSizeSacrificeToLeaveMine) > minRadius &&
        mineCoolDownCounter >= mineCoolDown }
    
    func mineSpawned() {
        //Called by GameScene after a mine has successfully been spawned at the player's tail
        targetRadius = targetRadius * (1-percentSizeSacrificeToLeaveMine)
        mineCoolDownCounter = 0
        minePropulsionSpeedActiveTimeCounter = 0
    }
    
    func angleToNode(node: SKNode) -> CGFloat {
        return mapRadiansToDegrees0to360((node.position - self.position).angle)
    }
    





    
}