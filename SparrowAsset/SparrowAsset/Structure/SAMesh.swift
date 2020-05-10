//
//  SAMesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

public struct SAMesh: BinaryCodable {
    public let name: String
    
    public let submeshes: [SASubmesh]
    
    public let vertexBuffer: Int // BufferView
    public let vertexAttributes: [SAVertexAttribute]
    
    public let min: SIMD3<Float>
    public let max: SIMD3<Float>
    
    public init(name: String, submeshes: [SASubmesh], vertexBuffer: Int, vertexAttributes: [SAVertexAttribute], min: SIMD3<Float>, max: SIMD3<Float>) {
        self.name = name
        self.submeshes = submeshes
        self.vertexBuffer = vertexBuffer
        self.vertexAttributes = vertexAttributes
        self.min = min
        self.max = max
    }
}

public enum SAVertexAttribute: UInt8, BinaryCodable {
    case position
    case normal
    case tangent
    case bitangent
    case uv0
    case uv1
    case color0
    case joints0
    case weights0
}
