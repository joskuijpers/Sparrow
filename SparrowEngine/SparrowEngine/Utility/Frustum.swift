//
//  Frustum.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 29/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// Frustum culling result
enum FrustumCullResult {
    /// Object is outside the frustum.
    case outside
    /// Object is fully inside the frustum.
    case inside
    /// Object is at least partially inside the frustum.
    case intersect
}

/**
 Frustum box, defined by 6 planes. Values in worldspace.
 
 Can be used to test Bounds intersection.
 
 - Note: The test is approximate, for culling only. Objects that are fully outside might be seen as inside or intersecting.
 
 - Note:
    ~~~
    https://research.ncl.ac.uk/game/mastersdegree/graphicsforgames/scenemanagement/Tutorial%207%20-%20Scene%20Management.pdf
    http://old.cescg.org/CESCG-2002/DSykoraJJelinek/
    https://www.gamedev.net/forums/topic/657702-creating-camera-bounding-frustum-from-view-and-projection-matrix/
    ~~~
 */
struct Frustum {
    let planes: [float4] // xyz=normal, w=distance
    
    /// Create a new Frustum using the camera view projection matrix
    ///
    /// - Parameter viewProjectionMatrix: The matrix from the camera.
    init(viewProjectionMatrix: float4x4) {
        var planes = [float4](repeating: .zero, count: 6)

        let (x, y, z, w) = viewProjectionMatrix.transpose.columns
        planes[0] = Frustum.planeNormalize(w + x) // left
        planes[1] = Frustum.planeNormalize(w - x) // right
        planes[2] = Frustum.planeNormalize(w + y) // bottom
        planes[3] = Frustum.planeNormalize(w - y) // top
        planes[4] = Frustum.planeNormalize(w + z) // near
        planes[5] = Frustum.planeNormalize(w - x) // far

        self.planes = planes
    }
    
    /// Get whether the bounds are (partially) within the frustum.
    ///
    /// - Parameter bounds: The bounds of the AABB to intersect with.
    /// - Returns: outside/inside/intersect, useful with quadtrees (outside -> no further scanning, inside -> draw all, intersect -> go deeper)
    @inlinable
    func intersects(bounds: Bounds) -> FrustumCullResult {
//        let radius = length(bounds.extents)
//        return intersects(sphereAt: bounds.center, radius: radius)
        let center = bounds.center
        let extents = bounds.extents
        var result: FrustumCullResult = .inside

        for i in 0..<6 {
            let plane = planes[i]

            let m = dot(center, plane.xyz)
            let n = dot(extents, abs(plane.xyz))

            if m + n < -plane.w {
                return .outside
            }
            if m - n < -plane.w {
                result = .intersect
            }
        }

        return result
    }
    
    /// Get whether the sphere is (partially) within the frustum.
    ///
    /// - Parameter position: Sphere center position.
    /// - Parameter radius: Sphere radius.
    /// - Returns: Whether the sphere is outside or inside
    @inlinable
    func intersects(sphereAt position: float3, radius: Float) -> FrustumCullResult {
        for i in 0..<6 {
            let plane = planes[i]
            if dot(position, plane.xyz) + plane.w <= -radius {
                return .outside
            }
        }
        return .inside
    }
    
    private static func planeNormalize(_ plane: float4) -> float4 {
        return plane / length(plane.xyz)
    }
}
