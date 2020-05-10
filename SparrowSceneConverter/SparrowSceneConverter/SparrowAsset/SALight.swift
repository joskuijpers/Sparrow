//
//  SALight.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

struct SALight: BinaryCodable {
    var type: SALightType
    
    // color, intensity, range, innerConeAngle, outerConeAngle
}

enum SALightType: UInt8, BinaryCodable {
    case directional
    case point
    case spot
}
