//
//  SASubmesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

public struct SASubmesh: BinaryCodable {
    public enum IndexType: UInt8, BinaryCodable {
        case uint16 = 0
        case uint32 = 1
    }
    
    public var indices: Int // BufferView
    public let material: Int
    
    public let min: SIMD3<Float>
    public let max: SIMD3<Float>
    
    public let indexType: IndexType
    
    public init(indices: Int, material: Int, min: SIMD3<Float>, max: SIMD3<Float>, indexType: IndexType) {
        self.indices = indices
        self.material = material
        self.min = min
        self.max = max
        self.indexType = indexType
    }
}
