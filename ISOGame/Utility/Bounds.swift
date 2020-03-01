//
//  BoundingBox.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 02/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import Metal

/**
Axis aligned bounding box for wrapping bounds of objects, in worldspace.
 */
struct Bounds {
    // The minimal point of the bounding box.
    let minBounds: float3
    
    // The maximal point of the bounding box.
    let maxBounds: float3
    
    /// The extents of the bounding box. This is half the size.
    let extents: float3
    
    /// The center of the bounding box.
    let center: float3
    
    
    public init() {
        minBounds = float3.zero
        maxBounds = float3.zero
        
        extents = ((maxBounds - minBounds) * 0.5) + minBounds
        center = float3.zero
    }
    
    /// A new bounding box with given extends in world space.
    public init(minBounds: float3, maxBounds: float3) {
        self.minBounds = minBounds
        self.maxBounds = maxBounds
        
        center = (minBounds + maxBounds) * 0.5
        extents = abs(maxBounds - center)
    }
    
    /// A new bounding box with given center in world space and extents.
    public init(center: float3, extents: float3) {
        self.minBounds = center - extents
        self.maxBounds = center + extents
        
        self.extents = extents
        self.center = center
    }
    
    /// Get whether the bounding box has a size of zero
    var isEmpty: Bool {
        return minBounds == float3.zero && maxBounds == float3.zero
    }
    
    /// The size of the bounding box.
    var size: float3 {
        return extents * 2.0
    }
    
    /// Get whether given world space point is contained within these bounds.
    // todo: test
    func contains(point: float3) -> Bool {
        // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter1/point_in_aabb.html
        return reduce_max(sign(point - minBounds)) <= 0 && reduce_max(sign(point - maxBounds)) >= 0
    }
    
    /// Get the closest point to given point, that lies on the bounding box.
    // todo: test
    func closest(point: float3) -> float3 {
        // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter1/closest_point_aabb.html
        // For each component: if p < min, closest is min. If p > max, closest is max. Otherwise, closest is p.
        // Do this for every axis and we're done. This is a clamp operation.
        return clamp(point, min: minBounds, max: maxBounds)
    }
    
//    func intersects(ray: Ray) -> Bool {
//    func intersects(ray: Ray, distance: out Float) -> Bool {
    // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html
//        return false // TODO
//    }
    
    /// Get whether this bounding box intersects another bounding box.
     func intersects(bounds: Bounds) -> Bool {
        // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter2/static_aabb_aabb.html
        
        // a.min <= b.max && a.max >= b.min
        return (minBounds.x <= bounds.maxBounds.x && maxBounds.x >= bounds.minBounds.x) &&
            (minBounds.y <= bounds.maxBounds.y && maxBounds.y >= bounds.minBounds.y) &&
            (minBounds.z <= bounds.maxBounds.z && maxBounds.z >= bounds.minBounds.z)
    }

    /// Smallest square distance between point and bounds.
    func squareDistance(point: float3) -> Float {
        return length_squared(max(max(minBounds - point, 0), point - maxBounds))
    }
}

extension Bounds: CustomDebugStringConvertible {
    var debugDescription: String {
        "Bounds(\(minBounds),\(maxBounds))"
    }
}

// MARK: - Math

extension Bounds {
    /// Grow the box to encapsulate the other bounding box.
    func encapsulate(_ other: Bounds) -> Bounds {
        let minimum = min(self.minBounds, other.minBounds)
        let maximum = max(self.maxBounds, other.maxBounds)
        
        return Bounds(minBounds: minimum, maxBounds: maximum)
    }
    
    /// Grow the box to encapsulate the point
    func encapsulate(_ point: float3) -> Bounds {
        let minimum = min(self.minBounds, point)
        let maximum = max(self.maxBounds, point)
        
        return Bounds(minBounds: minimum, maxBounds: maximum)
    }
    
    /// Multiply given AABB with a matrix, staying axis aligned. This is done by transforming every corner of the AABB and then creating a new AABB.
    static func * (left: Bounds, right: float4x4) -> Bounds {
        let center = right * float4(left.center, 1)
        return Bounds(center: center.xyz, extents: left.extents)
//        let ltf = (right * float4(left.minBounds.x, left.maxBounds.y, left.maxBounds.z, 1)).xyz
//        let rtf = (right * float4(left.maxBounds.x, left.maxBounds.y, left.maxBounds.z, 1)).xyz
//        let lbf = (right * float4(left.minBounds.x, left.minBounds.y, left.maxBounds.z, 1)).xyz
//        let rbf = (right * float4(left.maxBounds.x, left.minBounds.y, left.maxBounds.z, 1)).xyz
//        let ltb = (right * float4(left.minBounds.x, left.maxBounds.y, left.minBounds.z, 1)).xyz
//        let rtb = (right * float4(left.maxBounds.x, left.maxBounds.y, left.minBounds.z, 1)).xyz
//        let lbb = (right * float4(left.minBounds.x, left.minBounds.y, left.minBounds.z, 1)).xyz
//        let rbb = (right * float4(left.maxBounds.x, left.minBounds.y, left.minBounds.z, 1)).xyz
//
//        let minBounds = min(min(min(min(min(min(min(ltf, rtf), lbf), rbf), ltb), rtb), lbb), rbb)
//        let maxBounds = max(max(max(max(max(max(max(ltf, rtf), lbf), rbf), ltb), rtb), lbb), rbb)
//
//        return Bounds(minBounds: minBounds, maxBounds: maxBounds)
    }
    
    /// Get the union of two bounds.
    static func + (left: Bounds, right: Bounds) -> Bounds {
        return left.encapsulate(right)
    }
}
