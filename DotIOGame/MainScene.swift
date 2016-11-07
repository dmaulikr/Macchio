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
    
    var origin: SKNode!
    var playButton: MSButtonNode!
    var facebookButton: MSButtonNode!
    //var presetPlayerName: String?
    var playerNameText: UITextField! = nil
    var enteredPlayerName: String = ""
    
    var loadingImage: SKSpriteNode!
    
    override func didMove(to view: SKView) {
        
        if ResourceLoader.isInitialized {
            // Great! Resources are initialized!
        } else {
            ResourceLoader.initialize()
        }
        
        origin = childNode(withName: "origin")
        origin.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        loadingImage = childNode(withName: "//loadingImage") as! SKSpriteNode
        loadingImage.isUserInteractionEnabled = false
        loadingImage.size = self.size
        loadingImage.position = CGPoint(x: 0, y: self.size.height)
        
        playButton = childNode(withName: "//red orb") as! MSButtonNode
        playButton.selectedHandler = {
            self.loadingImage.position = CGPoint(x: 0, y: 0)
            
            let goToGameScene = SKAction.run {
                let skView = self.view as SKView!
                let scene = GameScene(fileNamed: "GameScene") as GameScene!
                scene?.scaleMode =  SKSceneScaleMode.resizeFill
                //scene.theEnteredInPlayerName = self.enteredPlayerName
                skView?.presentScene(scene)
            }
            let waitATinyBit = SKAction.wait(forDuration: 0.01)
            let sequence = SKAction.sequence([waitATinyBit, goToGameScene])
            self.playerNameText.removeFromSuperview()
            self.run(sequence)
            UserState.name = self.enteredPlayerName
        }
        
        facebookButton = childNode(withName: "//facebookButton") as! MSButtonNode
        facebookButton.selectedHandler = facebookButtonSelected
        
        // create the UITextField instance with positions... half of the screen width minus half of the textfield width.
        // Same for the height.
        playerNameText = UITextField(frame: CGRect(x: view.bounds.width / 2 - 125, y: view.bounds.height / 2 - 20 - 20, width: 250, height: 40))
        
        // add the UITextField to the GameScene's view
        view.addSubview(playerNameText)
        
        // add the gamescene as the UITextField delegate.
        // delegate funtion called is textFieldShouldReturn:
        playerNameText.delegate = self
        
        playerNameText.borderStyle = UITextBorderStyle.roundedRect
        playerNameText.textColor = SKColor.black
        playerNameText.placeholder = "Nickname"
        playerNameText.backgroundColor = SKColor.white
        playerNameText.autocorrectionType = UITextAutocorrectionType.no
//        if let presetPlayerName = presetPlayerName {
//            playerNameText.text = presetPlayerName
//            enteredPlayerName = presetPlayerName
//        }
        playerNameText.text = UserState.name
        enteredPlayerName = UserState.name
        
        playerNameText.clearButtonMode = UITextFieldViewMode.whileEditing
        playerNameText.autocapitalizationType = UITextAutocapitalizationType.none
        self.view!.addSubview(playerNameText)
        
        
    }
    
    func facebookButtonSelected() {
        print("fb pressed")
    }
    
    // Called by tapping return on the keyboard.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Populates the SKLabelNode
        enteredPlayerName = textField.text!
        
        // Hides the keyboard!
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            enteredPlayerName = text
        }
        textField.resignFirstResponder()
    }
    
    
}
