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

class Light: Node {
    private var data = LightData()
    
    let type: LightType
    var color = float3.one
    var intensity: Float = 1
    var direction = float3(0, -1, 0)
    
    init(type: LightType) {
        self.type = type
    }
    
    private func rebuildData() {
        switch (self.type) {
        case .directional:
            data.type = LightTypeDirectional
            data.color = color
            data.position = float4(direction, 0)
            
            // TODO: use Range! to cull the spotlight
            self.boundingBox = Bounds(minBounds: float3(-0.1, -0.1, -0.1), maxBounds: float3(0.1, 0.1, 0.1))
        case .point:
            data.type = LightTypePoint
            data.color = color
            data.position = self.worldTransform * float4(self.position, 1)
            
            self.boundingBox = Bounds(minBounds: float3(repeating: -Float.infinity), maxBounds: float3(repeating: Float.infinity))
        }
    }
    
    func build() -> LightData {
        return data
    }
}

class LightComponent: Component {
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
        
        super.init()
        
        rebuildData()
    }
    
    private func rebuildData() {
        switch (self.type) {
        case .directional:
            data.type = LightTypeDirectional
            data.color = color
            data.position = float4(direction, 0) // todo: replace direction with transform rotation
            
            // TODO: use Range! to cull the spotlight
//            self.boundingBox = Bounds(minBounds: float3(-0.1, -0.1, -0.1), maxBounds: float3(0.1, 0.1, 0.1))
        case .point:
            let transform = self.transform!
            
            data.type = LightTypePoint
            data.color = color
            
            data.position = transform.worldTransform * float4(transform.position, 1)
            
//            self.boundingBox = Bounds(minBounds: float3(repeating: -Float.infinity), maxBounds: float3(repeating: Float.infinity))
        }
    }
    
    /// Acquire the render system light data
    func build() -> LightData {
        return data
    }
}
