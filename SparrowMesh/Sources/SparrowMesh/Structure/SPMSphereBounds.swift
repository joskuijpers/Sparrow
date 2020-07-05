//
//  SPMSphereBounds.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 05/07/2020.
//

import SparrowBinaryCoder
import simd

/// Spherical bounds centered at origin.
public struct SPMSphereBounds: BinaryCodable {
    /// Radius of the sphere
    public let radius: Float
    
    /// Empty spherical bounds
    public init() {
        self.radius = 0
    }
    
    /// Spherical bounds with given radius
    public init(radius: Float) {
        self.radius = radius
    }
    
    /// Create a new bounds containing this and the given bounds.
    public func containing(_ other: SPMSphereBounds) -> SPMSphereBounds {
        return SPMSphereBounds(radius: max(self.radius, other.radius))
    }
    
    /// Create a new bounds containing this and the the given point
    public func containing(_ other: SIMD3<Float>) -> SPMBounds {
        return SPMSphereBounds(radius: max(self.radius, length(other)))
    }
}
