//
//  CGPointNeighbor.swift
//  JMCMarchingAnts
//
//  Created by Simon Kim on 2020/01/05.
//  Copyright © 2020 Janusz Chudzynski. All rights reserved.
//

import UIKit

enum CGPointNeighbor {
    case upper
    case lower
    case left
    case right
    case upperLeft
    case lowerLeft
    case upperRight
    case lowerRight
    
    var delta: CGPoint {
        switch(self) {
        case .upper: return CGPoint(x: 0, y: -1)
        case .lower: return CGPoint(x: 0, y: 1)
        case .left: return CGPoint(x: -1, y: 0)
        case .right: return CGPoint(x: 1, y: 0)
        case .upperLeft: return CGPoint(x: -1, y: -1)
        case .lowerLeft: return CGPoint(x: -1, y: 1)
        case .upperRight: return CGPoint(x: 1, y: -1)
        case .lowerRight: return CGPoint(x: 1, y: 1)
        }
    }
}

extension CGPoint {
    func adjacent(_ neighbor: CGPointNeighbor) -> CGPoint {
        return CGPoint(x: x + neighbor.delta.x, y: y + neighbor.delta.y)
    }
}
