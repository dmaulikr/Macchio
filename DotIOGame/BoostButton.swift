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
        super.init(texture: nil, color: SKColor.whiteColor(), size: CGSize(width: 100, height: 100))
        alpha = 0.001 //Basically u can't see it
        self.userInteractionEnabled = true
    }
    
    func addButtonIconToParent() {
        buttonIcon = SKSpriteNode(texture: iconTexture, size: CGSize(width: 80, height: 80)) //This size variable doesn't matter, as the actual hitbox of the button is independant of the size of the button icon
        buttonIcon.zPosition = self.zPosition - 1
        buttonIcon.alpha = 1
        buttonIcon.position = self.position
        parent!.addChild(buttonIcon)
        
        let path = NSBundle.mainBundle().pathForResource("TouchPoint", ofType: "sks")
        touchPointGraphic = SKReferenceNode (URL: NSURL (fileURLWithPath: path!))
        touchPointGraphic.userInteractionEnabled = false
        touchPointGraphic.zPosition += 0.01
        buttonIcon.addChild(touchPointGraphic)

    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        onPressed()
        touchPointGraphic.runAction(SKAction.fadeOutWithDuration(0.3))
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        onReleased()
    }
    
}
