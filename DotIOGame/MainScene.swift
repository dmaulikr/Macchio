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
    var playerNameText: UITextField! = nil
    var enteredPlayerName: String = ""
    override func didMoveToView(view: SKView) {
        playButton = childNodeWithName("red orb") as! MSButtonNode
        playButton.selectedHandler = {
            self.playerNameText.removeFromSuperview()
            let skView = self.view as SKView!
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            scene.scaleMode = .AspectFill
            scene.theEnteredInPlayerName = self.enteredPlayerName
            skView.presentScene(scene)
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
        playerNameText.placeholder = "Enter your name here"
        playerNameText.backgroundColor = SKColor.whiteColor()
        playerNameText.autocorrectionType = UITextAutocorrectionType.Yes
        
        playerNameText.clearButtonMode = UITextFieldViewMode.WhileEditing
        playerNameText.autocapitalizationType = UITextAutocapitalizationType.AllCharacters
        self.view!.addSubview(playerNameText)
        
//        highScoreText = UITextField(frame: CGRectMake(size.width/2, size.height/2+20, 320, 40))
//        highScoreText.borderStyle = UITextBorderStyle.RoundedRect
//        highScoreText.textColor = UIColor.whiteColor()
//        highScoreText.placeholder = "Enter your name in here"
//        highScoreText.backgroundColor = UIColor.darkGrayColor()
//        highScoreText.autocorrectionType = UITextAutocorrectionType.No
//        highScoreText.keyboardType = UIKeyboardType.ASCIICapable
//        highScoreText.clearButtonMode = UITextFieldViewMode.WhileEditing
//        highScoreText.autocapitalizationType = UITextAutocapitalizationType.None
//        self.view!.addSubview(highScoreText)
        
    }
    
    // Called by tapping return on the keyboard.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Populates the SKLabelNode
        enteredPlayerName = textField.text!
        
        // Hides the keyboard!
        textField.resignFirstResponder()
        return true
    }
    
    
}
