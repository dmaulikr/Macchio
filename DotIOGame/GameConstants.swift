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
    static let creature_speedDebuffTime: CGFloat = 2,
    creature_maxAngleChangePerSecond: CGFloat = 270
    static let alertPlayerAboutLargerCreaturesInRange: CGFloat = 500
    static let percentLargerACreatureMustBeToEngulfAnother: CGFloat = 1.11
    static let orbGrowAmount: [GameScene.OrbType: CGFloat] = [
        .Small : 800,
        .Rich : 2500
    ]
}