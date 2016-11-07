//
//  Mine.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/13/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class Mine: SKSpriteNode, BoundByCircle {
    
    static let shurikenTextures: [Color: SKTexture] = [
        .red : SKTexture(imageNamed: "shuriken_red"),
        .green : SKTexture(imageNamed: "shuriken_green"),
        .blue : SKTexture(imageNamed: "shuriken_blue"),
        .yellow : SKTexture(imageNamed: "shuriken_yellow")
    ]
    
    var radius: CGFloat = 100 //BS default values
    var growAmount: CGFloat = 100
    let lifeSpan: CGFloat = 2.0 //Constant to be tweaked
    var lifeCounter: CGFloat = 0
    var rps: CGFloat = 1 // Rotations per second
    var deltaRPSPerSecond: CGFloat = -1
    var leftByPlayerID: Int = 0
    var leftByPlayerColor: Color = .red

    init(radius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerWithID: Int, initialRPS: CGFloat = 1) {
        self.radius = radius
        self.growAmount = growAmount
        self.leftByPlayerColor = color
        let positiveRPS = CGFloat.random() > 0.5
        if positiveRPS { self.rps = initialRPS }
        else { self.rps = -initialRPS }
        self.deltaRPSPerSecond = -rps / lifeSpan
        
        let myTexture = Mine.shurikenTextures[color]
        self.leftByPlayerID = leftByPlayerWithID
        super.init(texture: myTexture, color: SKColor.white, size: CGSize(width: 2*radius * C.mine_sizeExaggeration , height: 2*radius * C.mine_sizeExaggeration))
        self.zRotation = CGFloat.random(min: 0, max: 360).degreesToRadians()
    }
    
    func belongsToCreature(_ creature: Creature) -> Bool {
        return creature.playerID == self.leftByPlayerID
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(_ deltaTime: CFTimeInterval) {
        rps += deltaRPSPerSecond * CGFloat(deltaTime)
        
        lifeCounter += CGFloat(deltaTime)
        zRotation += CGFloat(360 * rps).degreesToRadians() * CGFloat(deltaTime)
    }
    
}
