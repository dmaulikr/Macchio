//
//  LargePointDisplay.swift
//  Macchio
//
//  Created by Ryan Anderson on 8/14/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class LargePointDisplay: SKNode {
    
    // A node that can be used to display multipl labels for score increases that fade out after a bit
    // It will be this nodes responsibility to keep all the label nodes neatly scaled and arranged.
    // For this custom node, the origin will be at the BOTTOM-CENTER
    var masterLabels: MasterLabels!
    var size: CGSize!
    var pointLabels = [PointLabel]()
    let labelLifespan: CGFloat = 2
    
    init(size: CGSize) {
        masterLabels = MasterLabels()
        self.size = size
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addPointLabel(withText labelText: String) {
        let newLabel = masterLabels.largePointLabel.copy() as! SKLabelNode
        newLabel.text = labelText
        newLabel.position = CGPoint(x: 0, y: 0)
        newLabel.name = "pointLabel"
        pointLabels.insert(PointLabel(labelNode: newLabel, lifeCounter: 0), atIndex: 0) // The newest label is always inserted at the start
        self.addChild(newLabel)
        refreshLayout()
    }
    
    func refreshLayout() {
        // Uses SKActions to move around all the label nodes to look good and appear in chronological order.
        let allLabelNodes = pointLabels.map { $0.labelNode }
        for (index, labelNode) in allLabelNodes.enumerate() {
            let moveToProperPosition = SKAction.moveTo(CGPoint(x: 0, y: index * 40), duration: 0.25)
            labelNode.runAction(moveToProperPosition)
        }
    }
    
    func update(deltaTime: CGFloat) {
        for i in 0..<pointLabels.count {
            pointLabels[i].lifeCounter += deltaTime
            
            if pointLabels[i].lifeCounter > labelLifespan && pointLabels[i].labelNode.actionForKey("fadeOut") == nil {
                // That means this is a label node that has expired and is not yet fading. Time to start the process
                let fadeOutAction = SKAction.fadeOutWithDuration(1)
                pointLabels[i].labelNode.runAction(fadeOutAction, withKey: "fadeOut")
                
//                let waitForFadeToHappen = SKAction.waitForDuration(1)
//                let removeLabelNodeAndRefreshLayout = SKAction.runBlock {
//                }
//                self.runAction(SKAction.sequence([waitForFadeToHappen, removeLabelNodeAndRefreshLayout]))
            }
        }
        
        let childrenPointLabelNodes = (self.children.filter { $0 is SKLabelNode }) as! [SKLabelNode]
        for labelNode in childrenPointLabelNodes {
            if labelNode.alpha == 0 {
                labelNode.removeFromParent()
            }
        }
        pointLabels = pointLabels.filter { $0.labelNode.parent != nil }

        
    }
    
    
    struct PointLabel {
        let labelNode: SKLabelNode
        var lifeCounter: CGFloat = 0
    }
    
    
}