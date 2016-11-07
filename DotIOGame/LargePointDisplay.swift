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
    var currentTimestamp: CGFloat = 0
    var pointCoupler: PointCoupler = PointCoupler()
    
    init(size: CGSize) {
        masterLabels = MasterLabels()
        self.size = size
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addPointLabel(withText labelText: String, scale: CGFloat = 1) {
        let newLabel = masterLabels.largePointLabel.copy() as! SKLabelNode
        newLabel.text = labelText
        newLabel.position = CGPoint(x: 0, y: 0)
        newLabel.name = "pointLabel"
        newLabel.xScale = scale; newLabel.yScale = scale
        pointLabels.insert(PointLabel(labelNode: newLabel, lifeCounter: 0), at: 0) // The newest label is always inserted at the start
        self.addChild(newLabel)
        refreshLayout()
    }
    
    func refreshLayout() {
        // Uses SKActions to move around all the label nodes to look good and appear in chronological order.
        let allLabelNodes = pointLabels.map { $0.labelNode }
        for (index, labelNode) in allLabelNodes.enumerated() {
            let moveToProperPosition = SKAction.move(to: CGPoint(x: 0, y: index * 40), duration: 0.25)
            labelNode.run(moveToProperPosition)
        }
    }
    
    func showPoints(withValue value: Int) {
        // Allows coupling of points
        let ptInf = PointCoupler.PointInformation(value: value, timeStamp: currentTimestamp)
        pointCoupler.addPointInfo(ptInf)
    }
    
    func update(_ deltaTime: CGFloat) {
        currentTimestamp += deltaTime
        
        // Before managing all the label nodes that are currently floating around, let's see if the point coupler has anything for us to add.
        let couplerPoints = pointCoupler.reapCoupledPoints(currentTimestamp)
        if !couplerPoints.isEmpty {
            for pointValue in couplerPoints {
                let newLabelScale = CGFloat(pointValue) / CGFloat(100)
                addPointLabel(withText: "+\(pointValue)", scale: newLabelScale)
            }
        }
        
        for i in 0..<pointLabels.count {
            pointLabels[i].lifeCounter += deltaTime
            
            if pointLabels[i].lifeCounter > labelLifespan && pointLabels[i].labelNode.action(forKey: "fadeOut") == nil {
                // That means this is a label node that has expired and is not yet fading. Time to start the process
                let fadeOutAction = SKAction.fadeOut(withDuration: 1)
                pointLabels[i].labelNode.run(fadeOutAction, withKey: "fadeOut")
                
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

class PointCoupler {
    // There are some cases in the game in which the player scores points in quick succession, such as hitting
    // a big creature head-on with a mine, basically instantly killing them even though they technically shrink
    // first, then hit the mine again. All the smaller point fractions can't fit inside the screen, so points that have very close time stamps should be coupled together in the display. PointCoupler is a seperate object to aid in doing that.
    struct PointInformation {
        var value: Int
        let timeStamp: CGFloat
    }
    let coupleWorthyTimeDifference: CGFloat = 0.2
    var ptInfs = [PointInformation]()
    func addPointInfo(_ ptInf: PointInformation) {
        //Before adding to the array, see if there are any points it can be coupled with.
        var foundCouple = false
        if ptInfs.count > 0 {
            for i in 0..<ptInfs.count {
                if fabs(ptInfs[i].timeStamp - ptInf.timeStamp) <= coupleWorthyTimeDifference {
                    ptInfs[i].value += ptInf.value
                    foundCouple = true
                    break
                }
            }
        }
        
        if !foundCouple {
            ptInfs.append(ptInf)
        }
    }
    func reapCoupledPoints(_ currentTimestamp: CGFloat) -> [Int] {
        // remove all the point infos that are beyond coupling (expired timestamp) and return them in an array
        var returnVals = [Int]()
        if !ptInfs.isEmpty {
            for i in (ptInfs.count - 1)...0 {
                if currentTimestamp - ptInfs[i].timeStamp > coupleWorthyTimeDifference {
                    returnVals.append(ptInfs[i].value)
                    ptInfs.remove(at: i)
                }
            }
        }
        return returnVals
    }
}

