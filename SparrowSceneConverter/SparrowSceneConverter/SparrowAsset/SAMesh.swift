//
//  SAMesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SAMesh {
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

enum SAVertexAttribute {
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
