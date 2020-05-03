//
//  SASubmesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SASubmesh {
    var mesh: SAMesh?
    
    var indices: Int // BufferView
    var material: Int
    
    var vertexAttributes: [SAVertexAttribute]
}

enum SAVertexAttribute {
    case position
    case normal
    case tangent
    case uv0
    case uv1
    case color0
    case joints0
    case weights0
}
