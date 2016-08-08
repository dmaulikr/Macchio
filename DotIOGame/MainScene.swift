//
//  MainScene.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/15/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class MainScene: SKScene, UITextFieldDelegate {
    
    var playButton: MSButtonNode!
    var presetPlayerName: String?
    var playerNameText: UITextField! = nil
    var enteredPlayerName: String = ""
    
    var loadingImage: SKSpriteNode!
    
    override func didMoveToView(view: SKView) {
        loadingImage = childNodeWithName("loadingImage") as! SKSpriteNode
        loadingImage.userInteractionEnabled = false
        
        playButton = childNodeWithName("red orb") as! MSButtonNode
        playButton.selectedHandler = {
            self.loadingImage.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
            
            let goToGameScene = SKAction.runBlock {
                let skView = self.view as SKView!
                let scene = GameScene(fileNamed: "GameScene") as GameScene!
                scene.scaleMode = .AspectFill
                scene.theEnteredInPlayerName = self.enteredPlayerName
                skView.presentScene(scene)
            }
            let waitATinyBit = SKAction.waitForDuration(0.01)
            let sequence = SKAction.sequence([waitATinyBit, goToGameScene])
            self.playerNameText.removeFromSuperview()
            self.runAction(sequence)
        }
        
        // create the UITextField instance with positions... half of the screen width minus half of the textfield width.
        // Same for the height.
        playerNameText = UITextField(frame: CGRectMake(view.bounds.width / 2 - 160, view.bounds.height / 2 - 20, 320, 40))
        
        // add the UITextField to the GameScene's view
        view.addSubview(playerNameText)
        
        // add the gamescene as the UITextField delegate.
        // delegate funtion called is textFieldShouldReturn:
        playerNameText.delegate = self
        
        playerNameText.borderStyle = UITextBorderStyle.RoundedRect
        playerNameText.textColor = SKColor.blackColor()
        playerNameText.placeholder = "Nickname"
        playerNameText.backgroundColor = SKColor.whiteColor()
        playerNameText.autocorrectionType = UITextAutocorrectionType.No
        if let presetPlayerName = presetPlayerName {
            playerNameText.text = presetPlayerName
            enteredPlayerName = presetPlayerName
        }
        
        playerNameText.clearButtonMode = UITextFieldViewMode.WhileEditing
        playerNameText.autocapitalizationType = UITextAutocapitalizationType.None
        self.view!.addSubview(playerNameText)
        
        
    }
    
    // Called by tapping return on the keyboard.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Populates the SKLabelNode
        enteredPlayerName = textField.text!
        
        // Hides the keyboard!
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let text = textField.text {
            enteredPlayerName = text
        }
        textField.resignFirstResponder()
    }
    
    
}
