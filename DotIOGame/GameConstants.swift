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
    static let energyTransferPercent: CGFloat = 0.85 //energy transfer percent is the grow amount that is kept when energy changes state (e.g. creature ->X% mine ->X% orbs)
    static let creaturesToAreaRatio: CGFloat = 0.0000011
    static let orbsToAreaRatio: CGFloat = 0.00002
    
    static let camera_scaleMinimum: CGFloat = 2.5
    
    static let orbBeacon_minimumValueRequirement: CGFloat = 20000
    
    static let creature_hitMinePercentMassReduction: CGFloat = 0.5,
        creature_minimumRadiusToApplyMineSizeReductionInsteadOfInstantDeath: CGFloat = 80,
        creature_speedDebuffTime: CGFloat = 1.5,
        creature_maxAngleChangePerSecond: CGFloat = 270,
        creature_minePropulsionSpeedActiveTime: CGFloat = 0.25,
        creature_mineCooldownTime: CGFloat = 4.5,
        creature_minRadius: CGFloat = 50,
        creature_maxRadius: CGFloat = 350,
        creature_orbSpawnUponDeathRadiusMultiplier: CGFloat = 1.7,
    creature_deathFadeOutDuration: NSTimeInterval = 0.25
    static let percentLargerRadiusACreatureMustBeToEngulfAnother: CGFloat = 1.11
    
    static func creature_passiveScoreIncreasePerSecond(givenRadius r: CGFloat) -> CGFloat {
        return pow(2, r / 110) / 1.5
    }
    
    static func creature_passiveSizeLossPerSecond(givenRadius r: CGFloat) -> CGFloat {
        //return CGFloat( 1.25 * pow(2, (r-30)/100) - 1 )
        return r / 200
    }
    
    static func creature_normalSpeed(givenRadius r: CGFloat) -> CGFloat {
        //return 60 * pow(1/2, (r - 50) / 100) + 60
        return -r/6 + 160
    }
    
    static let alertPlayerAboutLargerCreaturesInRange: CGFloat = 500
    
    static let orb_growAmounts: [GameScene.OrbType: CGFloat] = [
        .Small : 154,
        .Rich : 1500,
        .Glorious: 707
    ]
    static let orb_minRadii: [GameScene.OrbType: CGFloat] = [
        .Small: 7,
        .Rich: 22,
        .Glorious: 15
    ]
    static let orb_maxRadii: [GameScene.OrbType: CGFloat] = [
        .Small: 9,
        .Rich: 26,
        .Glorious: 20
    ]
    static let orb_pointValues: [GameScene.OrbType: Int] = [
        .Small: 1,
        .Rich: 5,
        .Glorious: 5
    ]
    static let orb_artificialLifespan: CGFloat = 20 // The reason I have this constant is because if there is a big pile of orbs somewhere that's not being touched by the player or thte ai, it shouldn't clog up the cpu. This applies for the single player version at least.
    static let orb_fadeOutForXSeconds: CGFloat = 5
    static let mine_sizeExaggeration: CGFloat = 1.3 // Makes mines look bigger, but with the same hitbox.
    
    static let randomPlayerNames = [
        "Dont eat me",
        "Dont eat me!!1",
        "Frosty",
        "Names",
        "rage quit",
        "I should be doing homework",
        "Team, guys",
        "Dude... same",
        "Patrick Star",
        "I don't like you",
        "I WORK for MY fun!",
        "Scrublord",
        "DaliLabs",
        "CaliLabs",
        "Cat",
        "MLG QuickScoper",
        "Mtn Dew",
        "Doritos",
        "BLEEEEEEHHHH",
        "Aadkngjknas",
        "0_0",
        "0______0",
        "xx_Illuminati_xx",
        "Doge",
        "I WILL EAT U",
        "get away from me",
        "this game sucks",
        "agar.io clone!? D:",
        "Are you feeling it now mr crabs?",
        "Mr. Creeper",
        "Mr. Crabs",
        "Hmmmmmmmm",
        "Bob",
        "Casey",
        "Inky",
        "Blinky",
        "Clyde",
        "", "", "", "", "", "", "", "",
        "FeelTheBern2016",
        "XXx_Fabi0_xXX",
        "Team?",
        "Level 200 pro",
        "Say hi to Youtube!",
        "Pro team",
        "Foo", "Bar",
        "asdfghj",
        "qwerty",
        "Trump2016",
        "XXX_SLaYeR_XxX"
    ]
    
}