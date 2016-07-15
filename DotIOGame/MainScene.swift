//
//  MainScene.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/15/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class MainScene: SKScene {
    
    var playButton: MSButtonNode!
    
    override func didMoveToView(view: SKView) {
        playButton = childNodeWithName("playButton") as! MSButtonNode
        playButton.selectedHandler = {
            let skView = self.view as SKView!
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            scene.scaleMode = .AspectFill
            skView.presentScene(scene)
        }
    }
    
    
}
