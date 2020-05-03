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
    
    var submeshes: [SASubmesh] = []
    
    var vertexBuffer: Int // BufferView
//    var vertexAttributes
    
    
    
//    func addNormals(wotjAttributeNamed: String?, creaseThreshold: Float) {
//
//    }
    
    // https://developer.apple.com/documentation/modelio/mdlmesh/1391942-addtangentbasis
    func addTangentBasis(forTextureCoordinateAttributeNamed textureCoordinateAttributeName: String,
                         tangentAttributeNamed tangentAttributeName: String,
                         bitangentAttributeNamed bitangentAttributeName: String?) {
        
    }
}
