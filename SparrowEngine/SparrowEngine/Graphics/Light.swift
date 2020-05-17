//
//  Light.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 03/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

enum LightType {
    case directional
    case point
}

final class Light: Component {
    private var data = LightData()
    
    /// Type of the light
    let type: LightType
    
    /// Light color.
    var color = float3.one
    
    /// Light intensity (for spot and point lights)
    var intensity: Float = 1
    
    /// Light direction (for spot and directional lights). // TODO; replace with rotation of transform?
    var direction = float3(0, -1, 0)
    
    // TODO: add set/get Kelvin (color), Candela (intensity)
        // colorTemperature
    // range
    
    init(type: LightType) {
        self.type = type
    }
}
