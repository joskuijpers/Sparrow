//
//  SPMMesh.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// A mesh.
public struct SPMMesh: BinaryCodable {
    /// Name of the mesh.
    ///
    /// Debug use only.
    public let name: String
    
    /// List of submeshes.
    public let submeshes: [SPMSubmesh]
    
    /// Index of the buffer view that contains the vertices.
    public let vertexBuffer: Int
    
    /// List of vertex attributes.
    ///
    /// Order defines the order within the vertex buffer.
    public let vertexAttributes: [SPMVertexAttribute]
    
    /// Bounds encompassing all submeshes.
    public let bounds: SPMBounds
    
    /// Create a new mesh.
    public init(name: String, submeshes: [SPMSubmesh], vertexBuffer: Int, vertexAttributes: [SPMVertexAttribute], bounds: SPMBounds) {
        self.name = name
        self.submeshes = submeshes
        self.vertexBuffer = vertexBuffer
        self.vertexAttributes = vertexAttributes
        self.bounds = bounds
    }
}

/// Vertex attribute.
public enum SPMVertexAttribute: UInt8, BinaryCodable {
    /// Position vector. float3
    case position
    /// Normal vector. float3
    case normal
    /// Tangent vector. float3
    case tangent
    /// Bitangent vector. float3
    case bitangent
    /// First uv channel. float2
    case uv0
    /// Second uv channel. float2
    case uv1
    /// First color channel. float4
    case color0
    /// First joints channel.
    case joints0
    /// First weights channel.
    case weights0
}
