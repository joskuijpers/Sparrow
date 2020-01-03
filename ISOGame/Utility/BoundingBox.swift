//
//  BoundingBox.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 02/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct AxisAlignedBoundingBox {
    let minBounds: float3
    let maxBounds: float3
    
    public init() {
        minBounds = float3(repeating: 0)
        maxBounds = float3(repeating: 0)
    }
    
    public init(minBounds: float3, maxBounds: float3) {
        self.minBounds = minBounds
        self.maxBounds = maxBounds
    }
}

extension AxisAlignedBoundingBox {
    func union(other: AxisAlignedBoundingBox) -> AxisAlignedBoundingBox {
        let minimum = min(self.minBounds, other.minBounds)
        let maximum = max(self.maxBounds, other.maxBounds)
        
        return AxisAlignedBoundingBox(minBounds: minimum, maxBounds: maximum)
    }
}
