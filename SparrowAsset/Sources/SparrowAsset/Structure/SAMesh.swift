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
    
    public let bounds: SABounds
    
    public init(name: String, submeshes: [SASubmesh], vertexBuffer: Int, vertexAttributes: [SAVertexAttribute], bounds: SABounds) {
        self.name = name
        self.submeshes = submeshes
        self.vertexBuffer = vertexBuffer
        self.vertexAttributes = vertexAttributes
        self.bounds = bounds
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
