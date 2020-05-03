//
//  SASubmesh.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SASubmesh {
    var indices: Int // BufferView
    var material: Int
    
    var min: SIMD3<Float>
    var max: SIMD3<Float>
}
