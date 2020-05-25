//
//  SACamera.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

public struct SACamera: BinaryCodable {
    public var type: SACameraType
    
    public var aspectRatio: Float
    public var yfox: Float
    public var zfar: Float
    public var znear: Float
    
//    var xmag: Float
//    var ymag: Float
}

public enum SACameraType: UInt8, BinaryCodable {
    case perspective
//    case orthographic
}
