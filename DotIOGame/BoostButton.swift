//
//  BoostButton.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/13/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class BoostButton: SKSpriteNode {
    
    let defaultTexture = SKTexture(imageNamed: "boost_button_default")
    let pressedTexture = SKTexture(imageNamed: "boost_button_pressed")
    var onPressed: () -> Void = { print("No boost pressed action set") }
    var onReleased: () -> Void = { print("No boost realeased action set.") }
    var buttonIcon: SKSpriteNode!
    
    init() {
        super.init(texture: nil, color: SKColor.whiteColor(), size: CGSize(width: 150, height: 150))
        alpha = 0.3
        self.userInteractionEnabled = true
            }
    
    func addButtonIconToParent() {
        buttonIcon = SKSpriteNode(texture: defaultTexture, size: CGSize(width: 80, height: 80))
        buttonIcon.zPosition = self.zPosition - 1
        buttonIcon.alpha = 1
        buttonIcon.position = self.position
        parent!.addChild(buttonIcon)
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        buttonIcon.texture = pressedTexture
        onPressed()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        buttonIcon.texture = defaultTexture
        onReleased()
    }
    
}
