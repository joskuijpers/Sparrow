//
//  SACamera.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SACamera {
    var type: SACameraType
    
    var aspectRatio: Float
    var yfox: Float
    var zfar: Float
    var znear: Float
    
//    var xmag: Float
//    var ymag: Float
}

enum SACameraType {
    case perspective
//    case orthographic
}
