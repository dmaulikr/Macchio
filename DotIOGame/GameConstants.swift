//
//  GameConstants.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/22/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit
import Darwin

let pi = CGFloat(M_PI)

class C {
    // Not all game constants are here. Yet. My goal is for all of them to be here
    // Functions do count as constants.
    static let energyTransferPercent: CGFloat = 0.80
    static let creaturesToAreaRatio: CGFloat = 0.0000011
    static let orbsToAreaRatio: CGFloat = 0.00002
    
    static let orbBeacon_minimumValueRequirement: CGFloat = 20000
    
    static let creature_minePercentMassReduction: CGFloat = 0.5
    static let creature_minimumRadiusToApplyMineSizeReductionInsteadOfInstantDeath: CGFloat = 80
    static let creature_speedDebuffTime: CGFloat = 1.5,
        creature_maxAngleChangePerSecond: CGFloat = 270,
        creature_minePropulsionSpeedActiveTime: CGFloat = 0.25,
        creature_mineCooldownTime: CGFloat = 5.0,
        creature_minRadius: CGFloat = 50,
        creature_orbSpawnUponDeathRadiusMultiplier: CGFloat = 1.2
    static let percentLargerRadiusACreatureMustBeToEngulfAnother: CGFloat = 1.11
    
    static let alertPlayerAboutLargerCreaturesInRange: CGFloat = 500
    
    static let orb_growAmounts: [GameScene.OrbType: CGFloat] = [
        .Small : 800,
        .Rich : 1500,
        .Glorious: 100
    ]
    static let orb_minRadii: [GameScene.OrbType: CGFloat] = [
        .Small: 5,
        .Rich: 16,
        .Glorious: 20
    ]
    static let orb_maxRadii: [GameScene.OrbType: CGFloat] = [
        .Small: 7,
        .Rich: 20,
        .Glorious: 25
    ]
    static let orb_pointValues: [GameScene.OrbType: Int] = [
        .Small: 1,
        .Rich: 5,
        .Glorious: 0 // varies
    ]
    static let mine_sizeExaggeration: CGFloat = 1.3 // Makes mines look bigger, but with the same hitbox.
}