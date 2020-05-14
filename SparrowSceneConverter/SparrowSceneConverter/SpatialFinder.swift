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
    private let planeNormal = float3(0.8523, 0.34321, 0.5736)
    
    private var map: [Entry]
    
    init(_ positions: [float3]) {
        self.positions = positions
        
        map = []
        
        for (index, position) in positions.enumerated() {
            let distance = dot(position, planeNormal)
            map.append(Entry(index: index, distance: distance))
        }
    
        map.sort(by: { $0.distance < $1.distance })
    }
    
    // https://github.com/assimp/assimp/blob/master/code/Common/SpatialSort.cpp#L115
    func near(_ position: float3, radius: Float) -> [Int] {
        var result: [Int] = []
        
        // TODO: this is the simplest, worst performing implementation O(n)
        for entry in map {
            if distance(positions[entry.index], position) <= radius {
                result.append(entry.index)
            }
        }
        
        return result
    }
    
    struct Entry {
        let index: Int
        let distance: Float
    }
}
