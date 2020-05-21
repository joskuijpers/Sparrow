//
//  SASubmesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder
import Metal

public struct SASubmesh: BinaryCodable {
    public enum IndexType: UInt8, BinaryCodable {
        case uint16 = 0
        case uint32 = 1
        
        /// Get the size of an index element
        @inlinable
        public func size() -> Int {
            switch self {
            case .uint16:
                return MemoryLayout<UInt16>.size
            case .uint32:
                return MemoryLayout<UInt32>.size
            }
        }
        
        /// The MTLIndexType version
        @inlinable
        public func mtlType() -> MTLIndexType {
            return MTLIndexType(rawValue: UInt(self.rawValue))!
        }
    }
    
    public enum PrimitiveType: UInt8, BinaryCodable {
        case triangle
    }
    
    /// Name of the submesh. For debugging only.
    public let name: String
    
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
    
    public init(name: String, indices: Int, material: Int, bounds: SABounds, indexType: IndexType, primitiveType: PrimitiveType) {
        self.name = name
        self.indices = indices
        self.material = material
        self.bounds = bounds
        self.indexType = indexType
        self.primitiveType = primitiveType
    }
}
