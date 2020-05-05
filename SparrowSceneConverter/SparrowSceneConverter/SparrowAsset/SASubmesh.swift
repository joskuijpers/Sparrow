//
//  SASubmesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SASubmesh {
    enum IndexType {
        case uint16
        case uint32
    }
    
    var indices: Int // BufferView
    var material: Int
    
    var min: SIMD3<Float>
    var max: SIMD3<Float>
    
    var indexType: IndexType
}
