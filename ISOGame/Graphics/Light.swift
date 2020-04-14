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

class Light: Component {
    private var data = LightData()
    
    /// Type of the light
    let type: LightType
    
    /// Light color.
    var color = float3.one
    
    /// Light intensity (for spot and point lights)
    var intensity: Float = 1
    
    /// Light direction (for spot and directional lights). // TODO; replace with rotation of transform?
    var direction = float3(0, -1, 0)
    
    private var buildDataDirty = true
    
    // TODO: add set/get Kelvin (color), Candela (intensity)
        // colorTemperature
    // range
    
    init(type: LightType) {
        self.type = type
        
        super.init()
    }
    
    private func rebuildData() {
        switch (self.type) {
        case .directional:
            data.type = LightTypeDirectional
            data.color = color
            data.position = direction // TODO: replace direction with transform rotation
            data.range = Float.infinity
        case .point:
            data.type = LightTypePoint
            data.color = color
            
            data.position = self.transform!.worldPosition
            data.range = 5
        }
        
        buildDataDirty = false
    }
    
    /// Acquire the render system light data
    func build(into data: inout LightData) {
        if buildDataDirty {
            rebuildData()
        }
        
        data = self.data
    }
}
