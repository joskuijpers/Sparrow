//
//  Material.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 21/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal
import SparrowEngine2

/**
 A graphical material.
 */
public struct Material {
    /// Name of the material for debugging.
    public let name: String
    
    /// Render mode decides whether to use alpha texture.
    public let renderMode: RenderMode
    
    public let albedoTexture: MTLTexture?
    public let normalTexture: MTLTexture?
    public let roughnessMetalnessOcclusionTexture: MTLTexture?
    public let emissionTexture: MTLTexture?

    public let albedo: float3
    public let roughness: Float
    public let metalness: Float
    public let emission: float3
    
    public let alphaCutoff: Float
    public let alpha: Float
    
    public let doubleSided: Bool
    
    // TODO: shader! -> 2 shader function name strings -> Shader struct
    
    func buildShaderData() -> ShaderMaterialData {
        ShaderMaterialData(albedo: albedo,
                           emission: emission,
                           metallic: metalness,
                           roughness: roughness)
    }
    
    public static var `default`: Material = {
        Material(name: "default", renderMode: .opaque,
                 albedoTexture: nil, normalTexture: nil, roughnessMetalnessOcclusionTexture: nil, emissionTexture: nil,
                 albedo: [0.5,0.5,0.5], roughness: 1, metalness: 0, emission: float3.zero,
                 alphaCutoff: 0.2, alpha: 1,
                 doubleSided: false)
    }()
}
