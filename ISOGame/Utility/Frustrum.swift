//
//  Frustrum.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 29/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

enum FrustrumPlanePosition: Int {
    case left = 0, right, bottom, top, near, far
}

/// A frustrum plane
struct FrustrumPlane {
    let normal: float3
    let distance: Float
    
    /** Initialize with normal.
        Uses float4 because it is easier to handle coming from matrices. W is ignored.
     */
    init(normal: float4, distance: Float, isNormalized: Bool = false) {
        let normal = normal.xyz
        
        if isNormalized {
            self.normal = normal
            self.distance = distance
        } else {
            let length = sqrtf(dot(normal, normal))
            self.normal = normal / length
            self.distance = distance / length
        }
    }

    /// Calculate whether given sphere intersects with this plane.
    func intersects(sphereAt position: float3, radius: Float) -> Bool {
        if dot(position, normal) + distance <= -radius {
            return false
        }
        return true
    }
}

enum FrustrumCullResult {
    case outside, inside, intersect
}

/**
 Frustrum box, defined by 6 planes. Values in worldspace.
 
 Can be used to test Bounds intersection.
 
 https://research.ncl.ac.uk/game/mastersdegree/graphicsforgames/scenemanagement/Tutorial%207%20-%20Scene%20Management.pdf
 http://old.cescg.org/CESCG-2002/DSykoraJJelinek/
 */
struct Frustrum {
    let planes: [FrustrumPlane]
    
    init(viewProjectionMatrix: float4x4) {
        var planes = [FrustrumPlane]()
        
//        let (x, y, z, w) = viewProjectionMatrix.columns
        
        // transpose, then columns
        let x = float4(viewProjectionMatrix[0][0], viewProjectionMatrix[1][0], viewProjectionMatrix[2][0], viewProjectionMatrix[3][0])
        let y = float4(viewProjectionMatrix[0][1], viewProjectionMatrix[1][1], viewProjectionMatrix[2][1], viewProjectionMatrix[3][1])
        let z = float4(viewProjectionMatrix[0][2], viewProjectionMatrix[1][2], viewProjectionMatrix[2][2], viewProjectionMatrix[3][2])
        let w = float4(viewProjectionMatrix[0][3], viewProjectionMatrix[1][3], viewProjectionMatrix[2][3], viewProjectionMatrix[3][3])
        
        
        // column
        let w1 = viewProjectionMatrix[3][0]
        let w2 = viewProjectionMatrix[3][1]
        let w3 = viewProjectionMatrix[3][2]
        let w4 = viewProjectionMatrix[3][3]
        
        planes.append(FrustrumPlane(normal: w + x, distance: w4 + w1))
        planes.append(FrustrumPlane(normal: w - x, distance: w4 - w1))
        planes.append(FrustrumPlane(normal: w + y, distance: w4 + w2))
        planes.append(FrustrumPlane(normal: w - y, distance: w4 - w2))
        planes.append(FrustrumPlane(normal: w + z, distance: w4 + w3))
        planes.append(FrustrumPlane(normal: w - x, distance: w4 - w3))

        self.planes = planes
    }
    
    /// Get whether the bounds are (partially) within the frustrum.
    /// Returns outside/inside/intersect, useful with quadtrees (outside -> no further scanning, inside -> draw all, intersect -> go deeper)
    func intersects(bounds: Bounds) -> FrustrumCullResult {
        let center = bounds.center
        let extents = bounds.extents
        var result: FrustrumCullResult = .inside

        for plane in planes {
            let m = dot(center, plane.normal)
            let n = dot(extents, abs(plane.normal))

            if m + n < -plane.distance {
                return .outside
            }
            if m - n < -plane.distance {
                result = .intersect
            }

////            let nx = plane.normal.x > 0
////            let ny = plane.normal.y > 0
////            let nz = plane.normal.z > 0
////
////            let d = plane.normal.x * boxMinMax(bounds, nx).x + plane.normal.y * boxMinMax(bounds, ny).y + plane.normal.z * boxMinMax(bounds, nz).z
////
////            if d < -plane.distance {
////                return false
////            }
////
////            let d2 = plane.normal.x * boxMinMax(bounds, !nx).x + plane.normal.y * boxMinMax(bounds, !ny).y + plane.normal.z * boxMinMax(bounds, !nz).z
////            if d2 <= -plane.distance {
////                return true
////            }
        }

        return result
    }
    
    /// Get whether the sphere is (partially) within the frustrum.
    func intersects(sphereAt position: float3, radius: Float) -> Bool {
        for plane in planes {
            if !plane.intersects(sphereAt: position, radius: radius) {
                // Sphere is outside the plane (wrong side)
                return false
            }
        }
        return true
    }
}
