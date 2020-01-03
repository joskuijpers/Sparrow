//
//  Light.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 03/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

class Light: Node {
    
    
    func build() -> LightData {
        return LightData()
    }
}

class DirectionalLight: Light {
    var data = LightData()
    
    init(color: float3, direction: float3) {
        data.type = LightTypeDirectional
        data.color = color
        data.position = float4(direction, 0)
    }
    
    override func build() -> LightData {
        return data
    }
}

class PointLight: Light {
    var data = LightData()
    
    init(color: float3, intensity: Float) {
        data.type = LightTypePoint
        data.color = color
        // TODO: do something with intensity
        
        super.init()
        
        self.boundingBox = AxisAlignedBoundingBox(minBounds: float3(-0.1, -0.1, -0.1), maxBounds: float3(0.1, 0.1, 0.1))
    }
    
    override func build() -> LightData {
        data.position = self.worldTransform * float4(self.position, 1)
        return data
    }
}
