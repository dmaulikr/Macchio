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
    
    
//    let defaultTexture = SKTexture(imageNamed: "boost_button_default")
//    let pressedTexture = SKTexture(imageNamed: "boost_button_pressed")
    let iconTexture = SKTexture(imageNamed: "boost_button")
    let unableToPressTexture = SKTexture(imageNamed: "boost_button_pressed")
    var onPressed: () -> Void = { print("No boost pressed action set") }
    var onReleased: () -> Void = { print("No boost realeased action set.") }
    var buttonIcon: SKSpriteNode!
    var touchPointGraphic: SKReferenceNode!
    override var xScale: CGFloat {
        didSet { buttonIcon.xScale = self.xScale }
    }
    override var yScale: CGFloat {
        didSet { buttonIcon.yScale = self.yScale }
    }
    override var position: CGPoint {
        didSet { if let _ = buttonIcon { buttonIcon.position = position } }
    }
    
    init() {
        super.init(texture: nil, color: SKColor.white, size: CGSize(width: 100, height: 100))
        alpha = 0.001 //Basically u can't see it
        self.isUserInteractionEnabled = true
    }
    
    func addButtonIconToParent() {
        buttonIcon = SKSpriteNode(texture: iconTexture, size: CGSize(width: 80, height: 80)) //This size variable doesn't matter, as the actual hitbox of the button is independant of the size of the button icon
        buttonIcon.zPosition = self.zPosition - 1
        buttonIcon.alpha = 1
        buttonIcon.position = self.position
        parent!.addChild(buttonIcon)
        
        let path = Bundle.main.path(forResource: "TouchPoint", ofType: "sks")
        touchPointGraphic = SKReferenceNode (url: URL (fileURLWithPath: path!))
        touchPointGraphic.isUserInteractionEnabled = false
        touchPointGraphic.zPosition += 0.01
        buttonIcon.addChild(touchPointGraphic)

    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onPressed()
        touchPointGraphic.run(SKAction.fadeOut(withDuration: 0.3))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onReleased()
    }
    
}
