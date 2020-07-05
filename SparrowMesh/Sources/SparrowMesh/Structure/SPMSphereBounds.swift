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
    
    /// Create a new bounds containing all given spheres
    public static func containing(_ others: [SPMSphereBounds]) -> SPMSphereBounds {
        // TODO: how?
        return SPMSphereBounds()
    }

    /// Create a new bounds containing all given points
    public static func containing(_ points: [SIMD3<Float>]) -> SPMSphereBounds {
        // TODO https://en.wikipedia.org/wiki/Bounding_sphere
        
        // Inefficient implementation: loop over all items, find average. use as center
        // loop over all points, expending radius until all points fit.
        
        let total = points.reduce(SIMD3<Float>(0, 0, 0), +)
        let median = SIMD3<Float>(total.x / Float(points.count), total.y / Float(points.count), total.z / Float(points.count))
        
        var radiusSquared: Float = 0
        for point in points {
            radiusSquared = max(radiusSquared, length_squared(point - median))
        }
        let radius = sqrt(radiusSquared)
        
        return SPMSphereBounds(center: median, radius: radius)
    }
}
