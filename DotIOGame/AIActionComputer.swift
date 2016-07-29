//
//  AIDecisionComputer.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/26/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import Darwin

class AIActionComputer: NSObject {
    
    weak var gameScene: GameScene?
    weak var myCreature: AICreature?
    
    init(gameScene: GameScene, controlCreature myCreature: AICreature) {
        self.gameScene = gameScene
        self.myCreature = myCreature
    }
    
    func requestActions() {
        // add things to myCreatures pending actions array
    }
    
}