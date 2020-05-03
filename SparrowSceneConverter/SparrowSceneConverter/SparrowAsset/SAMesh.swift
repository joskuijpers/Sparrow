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
    
    var vertices: Int // BufferView
//    var vertexAttributes
}
