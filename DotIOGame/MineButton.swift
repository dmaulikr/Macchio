//
//  MineButton.swift
//  Macchio
//
//  Created by Ryan Anderson on 7/14/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class MineButton: SKSpriteNode {
    
    //let greenTexture = SKTexture(imageNamed: "shuriken_button_green") //TODO change the textures
    let greyTexture = SKTexture(imageNamed: "shuriken_button_grey")
    var onPressed: () -> Void = { print("No mine pressed action set") }
    var onReleased: () -> Void = { print("No mine realeased action set.") }
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
    
    var cropNode: SKCropNode!
    var greenPart: SKSpriteNode!
    
    init() {
        greenPart = SKSpriteNode(imageNamed: "green_circle_solid.png")
        super.init(texture: nil, color: SKColor.white, size: CGSize(width: 100, height: 100))
        alpha = 0.001 //Basically u can't see it. this is the hitbox
        self.isUserInteractionEnabled = true
    }
    
    func addButtonIconToParent() {
        buttonIcon = SKSpriteNode(texture: greyTexture, size: CGSize(width: 80, height: 80)) //This size variable doesn't matter, as the actual hitbox of the button is independant of the size of the button icon
        buttonIcon.zPosition = self.zPosition - 4
        buttonIcon.alpha = 1
        buttonIcon.position = self.position
        parent!.addChild(buttonIcon)
        
        cropNode = SKCropNode()
        cropNode.position = buttonIcon.position
        
        let maskNode = SKSpriteNode(imageNamed: "shuriken_button_grey.png")
        maskNode.size = buttonIcon.size
        greenPart.size = buttonIcon.size
        cropNode.maskNode = maskNode
        //cropNode.maskNode = nil
        cropNode.zPosition = self.zPosition - 3
        parent!.addChild(cropNode)
        
        greenPart.xScale = 1
        greenPart.yScale = 1
        greenPart.alpha = 1
        greenPart.zPosition = cropNode.zPosition + 1
        cropNode.addChild(greenPart)
        
        let path = Bundle.main.path(forResource: "TouchPoint", ofType: "sks")
        touchPointGraphic = SKReferenceNode (url: URL (fileURLWithPath: path!))
        touchPointGraphic.isUserInteractionEnabled = false
        touchPointGraphic.zPosition = self.zPosition - 1
        buttonIcon.addChild(touchPointGraphic)
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchPointGraphic.run(SKAction.fadeOut(withDuration: 0.3))
        onPressed()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onReleased()
    }

}
