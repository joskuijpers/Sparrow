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
    
    public enum PrimitiveType: UInt8, BinaryCodable {
        case triangle
    }
    
    /// Buffer view reference for the index buffer
    public var indices: Int
    
    /// Material reference for this submesh
    public let material: Int
    
    /// Bounds in model space.
    public let bounds: SABounds
    
    /// Index type: size of an index in the index buffer
    public let indexType: IndexType
    
    /// The type of primitive that is to be rendered.
    public let primitiveType: PrimitiveType
    
    public init(indices: Int, material: Int, bounds: SABounds, indexType: IndexType, primitiveType: PrimitiveType) {
        self.indices = indices
        self.material = material
        self.bounds = bounds
        self.indexType = indexType
        self.primitiveType = primitiveType
    }
}
