//
//  SANode.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

struct SANode: Codable {
    let name: String
    
    var matrix: matrix_float4x4 = matrix_identity_float4x4
    var children: [Int] = []
    
    var mesh: Int? = nil
    var camera: Int? = nil
    var light: Int? = nil
}

