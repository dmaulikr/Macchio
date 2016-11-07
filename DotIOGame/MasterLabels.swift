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
        largePointLabel = masterLabels.childNode(withName: "//largePointLabel") as! SKLabelNode
    }
    
    func loadSKSAsReferenceNode(_ fileName: String) -> SKReferenceNode {
        let resourcePath = Bundle.main.path(forResource: fileName, ofType: "sks")
        let referenceNode = SKReferenceNode(url: URL(fileURLWithPath: resourcePath!))
        return referenceNode
    }

    
    
}
