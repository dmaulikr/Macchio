//
//  LeaderBoard.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 8/3/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class LeaderBoard: SKNode {
    
    //The position of this node represents the lower left corner
    let numberOfSlots = 10
    let slotSize = CGSize(width: 500, height: 32)
    let slotPadding: CGFloat = 20
    
    var slotSprites = [SKSpriteNode]() //Represents the actual rectangles that make up the slots
    var entryLabels = [(place: SKLabelNode, playerName: SKLabelNode, score: SKLabelNode)!]() // 0  is first place. 1 = 2nd, etc
    var playerIDs = [Int]()
    var masterLabelNode: SKLabelNode!
    
    override init() {
        
        entryLabels = [(place: SKLabelNode, playerName: SKLabelNode, score: SKLabelNode)!](count: numberOfSlots, repeatedValue: nil)
        playerIDs = [Int](count: numberOfSlots, repeatedValue: 0)
        
        masterLabelNode = SKLabelNode(fontNamed: "Helvetica Neue UltraLight 32.0")
        masterLabelNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        masterLabelNode.zPosition = 1
        
        //Initialize empty slots. Just the sprite nodes. The slot sprites go from lowest to highest. So #10 to #1
        for slotIndex in 0..<numberOfSlots {
            let newSpriteNode = SKSpriteNode(color: UIColor.grayColor(), size: slotSize)
            newSpriteNode.anchorPoint = CGPoint(x: 0, y: 1)
            let position = CGPoint(x: 0, y: slotSize.height * CGFloat(slotIndex))
            newSpriteNode.position = position
            slotSprites.append(newSpriteNode)
            //self.addChild(newSpriteNode)
            
        }
        
        for (index, slotSprite) in slotSprites.enumerate() {
            let placeLabel = masterLabelNode.copy() as! SKLabelNode
            placeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
            placeLabel.text = "#\(numberOfSlots - index)"
            // When assigning positions, take into account the x: 0 and y: 1 anchor point for the slot node
            // place label goes to the left
            placeLabel.position = CGPoint(x: slotPadding, y: -slotSize.height/2)
            slotSprite.addChild(placeLabel)
            
            let playerNameLabel = masterLabelNode.copy() as! SKLabelNode
            playerNameLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            playerNameLabel.text = "N/A"
            // Player name goes in the center
            playerNameLabel.position = CGPoint(x: slotSize.width/2, y: -slotSize.height/2)
            slotSprite.addChild(playerNameLabel)
            
            let playerScoreLabel = masterLabelNode.copy() as! SKLabelNode
            playerScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
            playerScoreLabel.text = "N/A"
            // Score goes on the right
            playerScoreLabel.position = CGPoint(x: slotSize.width - slotPadding, y: -slotSize.height/2)
            slotSprite.addChild(playerScoreLabel)
            
            entryLabels[index] = (place: placeLabel, playerName: playerNameLabel, score: playerScoreLabel)
            //playerIDs[index] = 0
        }
        
        super.init()
        for slotSprite in slotSprites {
            self.addChild(slotSprite)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func update(creatureDataSnapshots: [CreatureDataSnapshot]) {
        
        // The data's should be sorted in order from lowest score to highest score
        let sortedData = creatureDataSnapshots.sort(byScore)
        
        // I'll have to handle a few cases. If I have less data than there are slots, then the slots will get filled up as much as they can, and leave the rest with blank default values. If I do have enough, things are easier.
        if sortedData.count < numberOfSlots {

            // Assign what I have in sorted data to
            for (index, data) in sortedData.enumerate() {
                    entryLabels[index].playerName.text = data.playerName
                    entryLabels[index].score.text = String(data.score)
                    playerIDs[index] = data.playerID
            }
        
            for i in sortedData.count-1..<numberOfSlots {
                entryLabels[i].playerName.text = "N/A"
                entryLabels[i].score.text = "N/A"
                playerIDs[i] = 0
            }
        } else {
            var theTop10Datas: [CreatureDataSnapshot] = []
            for index in sortedData.count - numberOfSlots..<sortedData.count {
                theTop10Datas.append(sortedData[index])
            }
            for (index, data) in theTop10Datas.enumerate() {
                entryLabels[index].playerName.text = data.playerName
                entryLabels[index].score.text = "\(data.score)"
                playerIDs[index] = data.playerID
            }
        }
        
    }
    
    struct CreatureDataSnapshot {
        let playerName: String
        let playerID: Int
        let score: UInt32
    }
    
    // This function is to be used for sorting
    func byScore(data1: CreatureDataSnapshot, data2: CreatureDataSnapshot) -> Bool {
        // should data1 go before data2 because it's score is higher? if yes, return true
        return data1.score < data2.score
    }
    
}
