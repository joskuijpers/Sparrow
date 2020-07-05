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
    /// Sphere center
    public let center: SIMD3<Float>
    
    /// Radius of the sphere
    public let radius: Float
    
    /// Empty spherical bounds
    public init() {
        self.center = [0, 0, 0]
        self.radius = 0
    }
    
    /// Spherical bounds with given radius
    public init(center: SIMD3<Float>, radius: Float) {
        self.center = center
        self.radius = radius
    }
    
    public init(box: SPMBounds) {
        self.center = (box.min + box.max) / 2
        
        self.radius = max(
            length(self.center, )
        )
    }
    
    /// Create a new bounds containing all given spheres
    public static func containing(_ others: [SPMSphereBounds]) -> SPMSphereBounds {
        // TODO: how?
        return SPMSphereBounds()
    }

    /// Create a new bounds containing all given points
    public static func containing(_ points: [SIMD3<Float>]) -> SPMSphereBounds {
        // TODO https://en.wikipedia.org/wiki/Bounding_sphere
        return SPMSphereBounds()
    }
}
