//
//  EnergyOrb.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/11/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class EnergyOrb: SKSpriteNode, BoundByCircle {
    
    static let orbTextures: [Color : SKTexture] = [
        .Blue: SKTexture.init(imageNamed: "blue_orb.png"),
        .Red: SKTexture.init(imageNamed: "red_orb.png"),
        .Green: SKTexture.init(imageNamed: "green_orb.png"),
        .Yellow: SKTexture.init(imageNamed: "yellow_orb.png")
    ]
    
    var radius: CGFloat = 15 {
        didSet {
            size = CGSize(width: radius * 2, height: radius * 2)
        }
    }
    var minRadius: CGFloat = 10, maxRadius: CGFloat = 15
    var growAmount: CGFloat = 1/5
    var lifespanCounter: CGFloat = 0
    var isAlive: Bool {
        return self.artificiallySpawned ? lifespanCounter < C.orb_artificialLifespan : true
    }
    var isNearDecay: Bool {
        return self.artificiallySpawned ? fabs(lifespanCounter - C.orb_artificialLifespan) <= C.orb_fadeOutForXSeconds : false
    }
    var isAlreadyFading = false
    
    var growing = true
    var artificiallySpawned = false // An artificially spawned orb will not be considered when the game tries to maintain a constant concentration of natural orbs (spawned from nothing)
    //var isEaten = false
    var type: GameScene.OrbType = GameScene.OrbType.Small
//    @objc override class func initialize() {
//        
//    }
    var pointValue: Int? // If it is nil, then hopefully the game will figure out the point value based on the type
    
    init(orbColor: Color, type: GameScene.OrbType, growFromNothing: Bool = true) {
        self.type = type
        let texture = EnergyOrb.orbTextures[orbColor]
        let color = SKColor.whiteColor()
        defer { radius = 0 }
        let size = CGSize(width: 2*radius, height: 2*radius)
        super.init(texture: texture, color: color, size: size)
        zPosition = 0
        blendMode = .Add
        
//        if true {
            // run a grow action, then pulse forever
            let growTime: NSTimeInterval = 0.5
            let growFromNothingAction = SKAction.customActionWithDuration(0.5, actionBlock: {
                (node: SKNode, timeElapsed: CGFloat) -> Void in
                self.radius = C.orb_minRadii[type]! * (timeElapsed / CGFloat(growTime))
            })
            self.runAction(growFromNothingAction, completion: pulseForever)
//        } else {
//            // fade in instead
//            self.alpha = 0
//            let fadeInTime: NSTimeInterval = 1
////            let fadeInAction = SKAction.customActionWithDuration(fadeInTime, actionBlock: {
////                (node: SKNode, elapsedTime: CGFloat) -> Void in
////                self.alpha = elapsedTime / CGFloat(fadeInTime)
////            })
//            let fadeInAction = SKAction.fadeInWithDuration(fadeInTime)
//            self.runAction(fadeInAction, completion: pulseForever)
//        }
        
    }
    
    func pulseForever() {

        let growDuration: NSTimeInterval = 0.5
        let growToMaxRadiusActionFromMinRadius = SKAction.customActionWithDuration(0.5, actionBlock: {
            (node: SKNode, timeElapsed: CGFloat) -> Void in
            let amountToUltimatelyGrow = C.orb_maxRadii[self.type]! - C.orb_minRadii[self.type]!
            self.radius = C.orb_minRadii[self.type]! + amountToUltimatelyGrow * (timeElapsed/CGFloat(growDuration))
        })
        
        let growToMinRadiusFromMaxRadius = SKAction.customActionWithDuration(growDuration, actionBlock: {
            (node: SKNode, timeElapsed: CGFloat) -> Void in
            let amountToUltimatelyShrink = C.orb_maxRadii[self.type]! - C.orb_minRadii[self.type]!
            self.radius = C.orb_maxRadii[self.type]! - amountToUltimatelyShrink * (timeElapsed/CGFloat(growDuration))
        })
        let sequence = SKAction.sequence([growToMaxRadiusActionFromMinRadius, growToMinRadiusFromMaxRadius])
        self.runAction(SKAction.repeatActionForever(sequence))
    }
    
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(deltaTime: CFTimeInterval) {
        if self.artificiallySpawned { lifespanCounter += CGFloat(deltaTime) }
//        if growing {
//            radius += 20 * CGFloat(deltaTime)
//            if radius >= maxRadius {growing = false}
//        } else {
//            radius -= 20 * CGFloat(deltaTime)
//            if radius <= minRadius {growing = true}
//        }
    }
    
    
    
}
