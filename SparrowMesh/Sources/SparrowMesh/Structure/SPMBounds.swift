//
//  SPMBounds.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder
import simd

/// Axis-aligned bounds.
public struct SPMBounds: BinaryCodable {
    /// Minimum-point.
    public let min: SIMD3<Float>
    
    /// Maximum-point.
    public let max: SIMD3<Float>
    
    /// A bounds containing all points.
    public init() {
        self.min = SIMD3<Float>(Float.infinity, Float.infinity, Float.infinity)
        self.max = SIMD3<Float>(-Float.infinity, -Float.infinity, -Float.infinity)
    }
    
    /// A bounds spanning between a minimum and maximum.
    public init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.min = min
        self.max = max
    }
    
    /// Create a new bounds containing this and the given bounds.
    public func containing(_ other: SPMBounds) -> SPMBounds {
        return SPMBounds(min: simd.min(min, other.min), max: simd.max(max, other.max))
    }
    
    /// Create a new bounds containing this and the the given point
    public func containing(_ other: SIMD3<Float>) -> SPMBounds {
        return SPMBounds(min: simd.min(min, other), max: simd.max(max, other))
    }
}
