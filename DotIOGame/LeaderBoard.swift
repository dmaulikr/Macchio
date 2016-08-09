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
    let slotSize = CGSize(width: 560, height: 32)
    let slotPadding: CGFloat = 20
    
    var slotSprites = [SKSpriteNode]() //Represents the actual rectangles that make up the slots
    var entryLabels = [(place: SKLabelNode, playerName: SKLabelNode, score: SKLabelNode)!]() // 0  is first place. 1 = 2nd, etc
    var playerIDs = [Int]()
    var masterLabelNode: SKLabelNode!
    var sortedData: [CreatureDataSnapshot] = []
    
    override init() {
        
        entryLabels = [(place: SKLabelNode, playerName: SKLabelNode, score: SKLabelNode)!](count: numberOfSlots, repeatedValue: nil)
        playerIDs = [Int](count: numberOfSlots, repeatedValue: 0)
        
        masterLabelNode = SKLabelNode(fontNamed: "Helvetica Neue UltraLight 32.0")
        masterLabelNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        masterLabelNode.zPosition = 1
        
        //Initialize empty slots. Just the sprite nodes. The slot sprites go from lowest to highest. So #10 to #1
        for slotIndex in 0..<numberOfSlots {
            //let newSpriteNode = SKSpriteNode(color: UIColor.grayColor(), size: slotSize)
            let blankTexture = SKTexture(imageNamed: "blankImage.png")
            let newSpriteNode = SKSpriteNode(texture: blankTexture, color: UIColor.grayColor(), size: slotSize)
            newSpriteNode.alpha = 1
            newSpriteNode.anchorPoint = CGPoint(x: 0, y: 0)
            let position = CGPoint(x: 0, y: slotSize.height * CGFloat(slotIndex))
            newSpriteNode.position = position
            slotSprites.append(newSpriteNode)
            //self.addChild(newSpriteNode)
            
        }
        
        for (index, slotSprite) in slotSprites.enumerate() {
            let placeLabel = masterLabelNode.copy() as! SKLabelNode
            placeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
            placeLabel.text = "#\(numberOfSlots - index)"
            // When assigning positions, take into account the x: 0 and y: 0 anchor point for the slot node
            // place label goes to the left
            placeLabel.position = CGPoint(x: slotPadding, y: slotSize.height/2)
            slotSprite.addChild(placeLabel)
            
            let playerNameLabel = masterLabelNode.copy() as! SKLabelNode
            playerNameLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
            playerNameLabel.text = "N/A"
            // Player name goes towards the left but not quite in the left
            playerNameLabel.position = CGPoint(x: slotPadding + 80, y: slotSize.height/2)
            slotSprite.addChild(playerNameLabel)
            
            let playerScoreLabel = masterLabelNode.copy() as! SKLabelNode
            playerScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
            playerScoreLabel.text = "N/A"
            // Score goes on the right
            playerScoreLabel.position = CGPoint(x: slotSize.width - slotPadding, y: slotSize.height/2)
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
        sortedData = creatureDataSnapshots.sort(byScore)
        
//        
//        let numberOfElementsToRead = sortedData.count <= numberOfSlots ? sortedData.count : numberOfSlots
//        var topDatas = [CreatureDataSnapshot]()
//        for index in sortedData.count - numberOfSlots ..< sortedData.count {
//            topDatas.append(sortedData[index])
//        }
//        
//        for blankIndex in 0..<numberOfSlots - topDatas.count {
//            let myEntryLabels = entryLabels[blankIndex]
//            myEntryLabels.playerName.text = ""
//            myEntryLabels.score.text = ""
//            myEntryLabels.playerName.color = UIColor.grayColor()
//        }
//        for (index, data) in topDatas
//        
        if sortedData.count < numberOfSlots {

            // Assign what I have in sorted data to
            for (index, data) in sortedData.enumerate() {
                    entryLabels[index].playerName.text = data.playerName
                    entryLabels[index].score.text = String(data.score)
                    let labelColor = gameSceneColorToUIColor(data.color)
                    entryLabels[index].place.fontColor = labelColor
                    entryLabels[index].playerName.fontColor = labelColor
                    entryLabels[index].score.fontColor = labelColor
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
                let labelColor = gameSceneColorToUIColor(data.color)
                entryLabels[index].place.fontColor = labelColor
                entryLabels[index].playerName.fontColor = labelColor
                entryLabels[index].score.fontColor = labelColor
                playerIDs[index] = data.playerID
            }
        }
        
    }
    
    func getRankOfCreature(withID creatureID: Int) -> Int? {
        // Note: sorted data is sorted from lowest score to highest score
        for (index, data) in sortedData.enumerate() {
            if data.playerID == creatureID {
                return sortedData.count - index
            }
        }
        return nil
    }
    
    struct CreatureDataSnapshot {
        let playerName: String
        let playerID: Int
        let score: Int
        let color: Color
    }
    
    // This function is to be used for sorting
    func byScore(data1: CreatureDataSnapshot, data2: CreatureDataSnapshot) -> Bool {
        // should data1 go before data2 because it's score is less? if yes, return true
        return data1.score < data2.score
    }
    
    func gameSceneColorToUIColor(inColor: Color) -> UIColor {
        switch inColor {
        case .Red:
            return UIColor(red: 255.0 / 255, green: 100.0 / 255, blue: 100.0 / 255, alpha: 1.0)
        case .Green:
            return UIColor(red: 100.0 / 255, green: 255.0 / 255, blue: 100.0 / 255, alpha: 1.0)
        case .Blue:
            return UIColor(red: 100.0 / 255, green: 100.0 / 255, blue: 255.0 / 255, alpha: 1.0)
        case .Yellow:
            return UIColor(red: 255.0 / 255, green: 255.0 / 255, blue: 100.0 / 255, alpha: 1.0)

        }
    }
    
}
