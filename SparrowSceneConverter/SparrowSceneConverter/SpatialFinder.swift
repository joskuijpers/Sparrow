//
//  SpatialSort.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 14/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import simd

struct SpatialFinder {
    private let positions: [float3]
    private static let planeNormal = float3(0.8523, 0.34321, 0.5736)
    
    private var entries: [Entry]
    
    init(_ positions: [float3]) {
        self.positions = positions
        
        entries = positions
            .enumerated()
            .map { index, position in
                Entry(index: index, distance: dot(position, SpatialFinder.planeNormal))
            }
            .sorted(by: { $0.distance < $1.distance })
    }
    
    // https://github.com/assimp/assimp/blob/master/code/Common/SpatialSort.cpp
    /// Find any positions within the radius near given position.
    func near(_ position: float3, radius: Float) -> [Int] {
        var result: [Int] = []
        
        if positions.count == 0 {
            return result
        }
        
        let dist = dot(position, SpatialFinder.planeNormal)
        let minDist = dist - radius
        let maxDist = dist + radius
        
        if maxDist < entries.first!.distance {
            return result
        }
        if minDist > entries.last!.distance {
            return result
        }
        
        // Do a binary search
        var index = entries.count / 2
        var stepSize = entries.count / 4
        
        while stepSize > 1 {
            if entries[index].distance < minDist {
                index += stepSize
            } else {
                index -= stepSize
            }
            
            stepSize /= 2
        }

        // May need one more step to get to the actual index
        while index > 0 && entries[index].distance > minDist {
            index -= 1
        }
        while index < entries.count - 1 && entries[index].distance < minDist {
            index += 1
        }
        
        let squared = radius * radius
        while index < entries.count && entries[index].distance < maxDist {
            let entry = entries[index]
            if length_squared(positions[entry.index] - position) < squared {
                result.append(entry.index)
            }
            
            index += 1
        }

        return result
    }
    
    private struct Entry {
        let index: Int
        let distance: Float
    }
}
