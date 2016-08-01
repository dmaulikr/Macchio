//
//  GameConstants.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/22/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class C {
    // Not all game constants are here. Yet. My goal is for all of them to be here
    // Functions do count as constants.
    static let creature_speedDebuffTime: CGFloat = 1,
        creature_maxAngleChangePerSecond: CGFloat = 270,
        creature_minePropulsionSpeedActiveTime: CGFloat = 0.25,
        creature_mineCooldownTime: CGFloat = 4.0,
        creature_minRadius: CGFloat = 50
    static let alertPlayerAboutLargerCreaturesInRange: CGFloat = 500
    static let percentLargerRadiusACreatureMustBeToEngulfAnother: CGFloat = 1.11
    static let orbGrowAmount: [GameScene.OrbType: CGFloat] = [
        .Small : 800,
        .Rich : 2500
    ]
    static let mine_sizeExaggeration: CGFloat = 1.3 // Makes mines look bigger, but with the same hitbox.
}