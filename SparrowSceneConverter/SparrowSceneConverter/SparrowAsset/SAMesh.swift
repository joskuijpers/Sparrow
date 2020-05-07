//
//  SAMesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SAMesh: Codable {
    let name: String
    
    var submeshes: [SASubmesh]
    
    var vertexBuffer: Int // BufferView
    var vertexAttributes: [SAVertexAttribute]
    
    var min: SIMD3<Float>
    var max: SIMD3<Float>
    
//    func addNormals(wotjAttributeNamed: String?, creaseThreshold: Float) {
//
//    }
    
    // https://developer.apple.com/documentation/modelio/mdlmesh/1391942-addtangentbasis
    func addTangentBasis(forTextureCoordinateAttributeNamed textureCoordinateAttributeName: String,
                         tangentAttributeNamed tangentAttributeName: String,
                         bitangentAttributeNamed bitangentAttributeName: String?) {
        
    }
}

enum SAVertexAttribute: UInt8 {
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

extension SAVertexAttribute: Codable {
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
       case unknownValue
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let rawValue = try container.decode(UInt8.self)
        
        guard let value = SAVertexAttribute(rawValue: rawValue) else {
            throw CodingError.unknownValue
        }
        
        self = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.rawValue)
    }
}

