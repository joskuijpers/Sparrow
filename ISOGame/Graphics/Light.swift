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
    
    /// Bounding box.
    private(set) var bounds: Bounds = Bounds(minBounds: float3(repeating: -Float.infinity), maxBounds: float3(repeating: Float.infinity))
    
    private var buildDataDirty = true
    
    // TODO: add set/get Kelvin (color), Candela (intensity)
        // colorTemperature
    // range
    
    init(type: LightType) {
        self.type = type
        
        super.init()
    }
    
    required init() {
        self.type = .point
        
        super.init()
    }
    
    private func rebuildData() {
        switch (self.type) {
        case .directional:
            data.type = LightTypeDirectional
            data.color = color
            data.position = float4(direction, 0) // todo: replace direction with transform rotation
            data.range = Float.infinity
        case .point:
            let transform = self.transform!
            
            data.type = LightTypePoint
            data.color = color
            
            data.position = transform.worldTransform * float4(transform.position, 1)
            data.range = 5
            
//            let range: Float = 5
//            self.bounds = Bounds(center: data.position.xyz, extents: float3(range, range, range))
        }
    }
    
    /// Acquire the render system light data
    func build() -> LightData {
        if buildDataDirty {
            rebuildData()
        }
        return data
    }
}
