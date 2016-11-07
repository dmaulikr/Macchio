//
//  BoundByCircle.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/12/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

let sqrt2: CGFloat = 1.4142135623730950488

protocol BoundByCircle {
    var radius: CGFloat { get }
    var position: CGPoint { get }
    func overlappingCircle(_ other: BoundByCircle) -> Bool
}

extension BoundByCircle {
    func overlappingCircle(_ other: BoundByCircle) -> Bool {
        return position.distanceTo(other.position) < radius + other.radius
    }
    
    func pointOnCircleClosestToOtherPoint(_ otherPoint: CGPoint, circlePosition: CGPoint) -> CGPoint {
        if circlePosition.distanceTo(otherPoint) <= radius {
            return otherPoint
        } else {
            let angleToOtherPoint = (otherPoint - circlePosition).angle
            let x = circlePosition.x + cos(angleToOtherPoint) * radius
            let y = circlePosition.y + sin(angleToOtherPoint) * radius
            return CGPoint(x: x, y: y)
        }
    }
    
    var pointRight: CGPoint {
        return CGPoint(x: position.x + radius, y: position.y)
    }
    var point45Deg: CGPoint {
        return CGPoint(x: position.x + radius/sqrt2, y: position.y + radius/sqrt2)
    }
    var pointTop: CGPoint {
        return CGPoint(x: position.x, y: position.y + radius)
    }
    var point135Deg: CGPoint {
        return CGPoint(x: position.x - radius/sqrt2, y: position.y + radius/sqrt2)
    }
    var pointLeft: CGPoint {
        return CGPoint(x: position.x - radius, y: position.y)
    }
    var point225Deg: CGPoint {
        return CGPoint(x: position.x - radius/sqrt2, y: position.y - radius/sqrt2)
    }
    var pointBottom: CGPoint {
        return CGPoint(x: position.x, y: position.y - radius)
    }
    var point315Deg: CGPoint {
        return  CGPoint(x: position.x + radius/sqrt2, y: position.y - radius/sqrt2)
    }
    var nineNotablePoints: [CGPoint] {
        return [
            position,
            pointRight,
            point45Deg,
            pointTop,
            point135Deg,
            pointLeft,
            point225Deg,
            pointBottom,
            point315Deg,
        ]
    }
}
