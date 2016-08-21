//
//  MasterLabels.swift
//  Macchio
//
//  Created by Ryan Anderson on 8/16/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class MasterLabels {
    var masterLabels: SKReferenceNode!
    var largePointLabel: SKLabelNode!
    init() {
        masterLabels = loadSKSAsReferenceNode("MasterLabels")
        largePointLabel = masterLabels.childNodeWithName("//largePointLabel") as! SKLabelNode
    }
    
    func loadSKSAsReferenceNode(fileName: String) -> SKReferenceNode {
        let resourcePath = NSBundle.mainBundle().pathForResource(fileName, ofType: "sks")
        let referenceNode = SKReferenceNode(URL: NSURL(fileURLWithPath: resourcePath!))
        return referenceNode
    }

    
    
}
