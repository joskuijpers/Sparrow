//
//  SALight.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SALight {
    var type: SALightType
    
    // color, intensity, range, innerConeAngle, outerConeAngle
}

enum SALightType {
    case directional
    case point
    case spot
}
