//
//  Material.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 21/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 A graphical material.
 */
struct Material {
    /// Name of the material for debugging.
    let name: String
    
    /// Render mode decides whether to use alpha texture.
    let renderMode: RenderMode
    
    let albedoTexture: MTLTexture?
    let normalTexture: MTLTexture?
    let roughnessMetalnessOcclusionTexture: MTLTexture?
    let emissionTexture: MTLTexture?

    let albedo: float3
    let roughness: Float
    let metalness: Float
    let emission: float3
    
    let alphaCutoff: Float
    let alpha: Float
    
    // TODO: shader! -> 2 shader function name strings
    
    func buildShaderData() -> ShaderMaterialData {
        ShaderMaterialData(albedo: albedo,
                           emission: emission,
                           metallic: metalness,
                           roughness: roughness)
    }
    
    static var `default`: Material = {
        Material(name: "default", renderMode: .opaque,
                 albedoTexture: nil, normalTexture: nil, roughnessMetalnessOcclusionTexture: nil, emissionTexture: nil,
                 albedo: [0.5,0.5,0.5], roughness: 1, metalness: 0, emission: float3.zero,
                 alphaCutoff: 0.2, alpha: 1)
    }()
}
