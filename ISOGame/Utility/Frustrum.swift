//
//  Frustrum.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 29/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// Frustrum culling result
enum FrustrumCullResult {
    /// Object is outside the frustrum.
    case outside
    /// Object is fully inside the frustrum.
    case inside
    /// Object is at least partially inside the frustrum.
    case intersect
}

/**
 Frustrum box, defined by 6 planes. Values in worldspace.
 
 Can be used to test Bounds intersection.
 
 - Note: The test is approximate, for culling only. Objects that are fully outside might be seen as inside or intersecting.
 
 - Note:
    ~~~
    https://research.ncl.ac.uk/game/mastersdegree/graphicsforgames/scenemanagement/Tutorial%207%20-%20Scene%20Management.pdf
    http://old.cescg.org/CESCG-2002/DSykoraJJelinek/
    https://www.gamedev.net/forums/topic/657702-creating-camera-bounding-frustum-from-view-and-projection-matrix/
    ~~~
 */
struct Frustrum {
    let planes: [float4] // xyz=normal, w=distance
    
    /// Create a new Frustrum using the camera view projection matrix
    ///
    /// - Parameter viewProjectionMatrix: The matrix from the camera.
    init(viewProjectionMatrix: float4x4) {
        var planes = [float4](repeating: .zero, count: 6)

        let (x, y, z, w) = viewProjectionMatrix.transpose.columns
        planes.append(normalize(w + x)) // left
        planes.append(normalize(w - x)) // right
        planes.append(normalize(w + y)) // bottom
        planes.append(normalize(w - y)) // top
        planes.append(normalize(w + z)) // near
        planes.append(normalize(w - x)) // far

        self.planes = planes
    }
    
    /// Get whether the bounds are (partially) within the frustrum.
    ///
    /// - Parameter bounds: The bounds of the AABB to intersect with.
    /// - Returns: outside/inside/intersect, useful with quadtrees (outside -> no further scanning, inside -> draw all, intersect -> go deeper)
    func intersects(bounds: Bounds) -> FrustrumCullResult {
        let center = bounds.center
        let extents = bounds.extents
        var result: FrustrumCullResult = .inside

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
    
    /// Get whether the sphere is (partially) within the frustrum.
    ///
    /// - Parameter position: Sphere center position.
    /// - Parameter radius: Sphere radius.
    /// - Returns: Whether the sphere is outside or inside
    func intersects(sphereAt position: float3, radius: Float) -> FrustrumCullResult {
        for i in 0..<6 {
            let plane = planes[i]
            if dot(position, plane.xyz) + plane.w <= -radius {
                return .outside
            }
        }
        return .inside
    }
}