//
//  Light.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 03/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowECS

/// Type of a light
public enum LightType: UInt8, Codable {
    /// A light source with a uniform direction and constant intensity.
    case directional
    
    /// An omnidirectional light.
    case point
    
    /// A light source that illuminates a cone-shaped area.
//    case spot
}

/// A light source.
public final class Light: Component {
    /// Type of the light.
    public let type: LightType
    
    /// Light color.
    ///
    /// The actual color is determined by multiplying the `temperature` color with `color`.
    public var color = float3.one

    /// The temperature of the light in Kelvin.
    ///
    /// The actual color is determined by multiplying the `temperature` color with `color`.
    public var temperature: Int = 6500
    
    /// The intensity of the light in Candela
    public var intensity: Float = 1
//    public var intensity: Float = 1000 // LUMENS???
    
    
    // spotInnerAngle, spotOuterAngle
    // range / attenuationStartDistance, attenuationEndDistance, attenuationFalloffExponent
    
    //    public var castsShadow: Bool = false
    // shadowMapSize, shadowBias
    // zNear, zFar, orthographicScale
    
    public init(type: LightType) {
        self.type = type
    }
}

extension Light: Storable {}
