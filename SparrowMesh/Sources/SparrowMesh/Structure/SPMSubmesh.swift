//
//  SPMSubmesh.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder
import Metal

/// A submesh of a mesh.
///
/// Contains a material and a reference to an index buffer, together with some utilities.
public struct SPMSubmesh: BinaryCodable {
    
    /// Index type and size.
    public enum IndexType: UInt8, BinaryCodable {
        /// Two-byte unsigned int index
        case uint16 = 0
        /// Four-byte unsigned int index
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
    
    /// Type of the primitive the submesh consists of.
    public enum PrimitiveType: UInt8, BinaryCodable {
        /// Index buffer contains a list of triangles.
        case triangle
    }
    
    /// Name of the submesh. For debugging only.
    public let name: String
    
    /// Buffer view reference for the index buffer
    public var indices: Int
    
    /// Material reference for this submesh
    public let material: Int
    
    /// Bounds in model space.
    public let bounds: SPMBounds
    
    /// Index type: size of an index in the index buffer
    public let indexType: IndexType
    
    /// The type of primitive that is to be rendered.
    public let primitiveType: PrimitiveType
    
    /// Create a new submesh.
    public init(name: String, indices: Int, material: Int, bounds: SPMBounds, indexType: IndexType, primitiveType: PrimitiveType) {
        self.name = name
        self.indices = indices
        self.material = material
        self.bounds = bounds
        self.indexType = indexType
        self.primitiveType = primitiveType
    }
}
