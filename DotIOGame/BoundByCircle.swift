//
//  BoundByCircle.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/12/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

protocol BoundByCircle {
    var radius: CGFloat { get }
    var position: CGPoint { get }
    func overlappingCircle(other: BoundByCircle) -> Bool
}

extension BoundByCircle {
    func overlappingCircle(other: BoundByCircle) -> Bool {
        return position.distanceTo(other.position) < radius + other.radius
    }
}