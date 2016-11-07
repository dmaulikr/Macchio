//
//  ResourceLoader.swift
//  Macchio
//
//  Created by Ryan Anderson on 8/16/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

class ResourceLoader {
    
    static var isInitialized: Bool = false
    static var masterLabels: SKReferenceNode!
    
    static func initialize() {
        isInitialized = true
        //masterLabels = ResourceLoader.loadSKSAsReferenceNode("masterLabels")
    }
    
    static func loadSKSAsReferenceNode(_ fileName: String) -> SKReferenceNode {
        let resourcePath = Bundle.main.path(forResource: fileName, ofType: "sks")
        let referenceNode = SKReferenceNode(url: URL(fileURLWithPath: resourcePath!))
        return referenceNode
    }
    
    // TODO add mroe resources

}
