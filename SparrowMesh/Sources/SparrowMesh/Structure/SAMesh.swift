//
//  SAMesh.swift
//  SparrowAsset
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// A mesh.
public struct SAMesh: BinaryCodable {
    /// Name of the mesh.
    ///
    /// Debug use only.
    public let name: String
    
    /// List of submeshes.
    public let submeshes: [SASubmesh]
    
    /// Index of the buffer view that contains the vertices.
    public let vertexBuffer: Int
    
    /// List of vertex attributes.
    ///
    /// Order defines the order within the vertex buffer.
    public let vertexAttributes: [SAVertexAttribute]
    
    /// Bounds encompassing all submeshes.
    public let bounds: SABounds
    
    /// Create a new mesh.
    public init(name: String, submeshes: [SASubmesh], vertexBuffer: Int, vertexAttributes: [SAVertexAttribute], bounds: SABounds) {
        self.name = name
        self.submeshes = submeshes
        self.vertexBuffer = vertexBuffer
        self.vertexAttributes = vertexAttributes
        self.bounds = bounds
    }
}

/// Vertex attribute.
public enum SAVertexAttribute: UInt8, BinaryCodable {
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
