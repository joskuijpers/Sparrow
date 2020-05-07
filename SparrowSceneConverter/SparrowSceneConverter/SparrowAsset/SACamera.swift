//
//  SACamera.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SACamera: Codable {
    var type: SACameraType
    
    var aspectRatio: Float
    var yfox: Float
    var zfar: Float
    var znear: Float
    
//    var xmag: Float
//    var ymag: Float
}

enum SACameraType: UInt8, Codable {
    case perspective
//    case orthographic
}
