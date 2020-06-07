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
public struct Material {
    /// Name of the material for debugging.
    public let name: String
    
    /// Render mode decides whether to use alpha texture.
    public let renderMode: RenderMode
    
    /// The albedo texture, with alpha in the alpha channel.
    public let albedoTexture: MTLTexture?
    
    /// Normal texture.
    public let normalTexture: MTLTexture?
    
    /// RMO texture. Roughness in red, metalness in green and ambient occlusion in blue channel.
    public let roughnessMetalnessOcclusionTexture: MTLTexture?
    
    /// Emission texture.
    public let emissionTexture: MTLTexture?

    /// Albedo color.
    public let albedo: float3
    
    /// Roughness.
    public let roughness: Float
    
    /// Metalness. 0 is dielectric, 1 is fully metallic.
    public let metalness: Float
    
    /// Emission. Added to total bounced light.
    public let emission: float3
    
    /// Cutoff for alpha, used for alpha texture.
    public let alphaCutoff: Float
    
    /// Alpha of the whole material.
    public let alpha: Float
    
    /// Rendering doublesided. (When true, back culling is disabled)
    public let doubleSided: Bool
    
    // TODO: shader! -> 2 shader function name strings -> Shader struct
    
    public init(name: String,
                renderMode: RenderMode,
                albedoTexture: MTLTexture?,
                normalTexture: MTLTexture?,
                roughnessMetalnessOcclusionTexture: MTLTexture?,
                emissionTexture: MTLTexture?,
                albedo: float3,
                roughness: Float,
                metalness: Float,
                emission: float3,
                alphaCutoff: Float,
                alpha: Float,
                doubleSided: Bool) {
        self.name = name
        self.renderMode = renderMode
        self.albedoTexture = albedoTexture
        self.normalTexture = normalTexture
        self.roughnessMetalnessOcclusionTexture = roughnessMetalnessOcclusionTexture
        self.emissionTexture = emissionTexture
        self.albedo = albedo
        self.roughness = roughness
        self.metalness = metalness
        self.emission = emission
        self.alphaCutoff = alphaCutoff
        self.alpha = alpha
        self.doubleSided = doubleSided
    }
    
    /// Build the shader uniform data for this material.
    public func buildShaderData() -> ShaderMaterialData {
        ShaderMaterialData(albedo: albedo,
                           emission: emission,
                           metallic: metalness,
                           roughness: roughness)
    }
    
    /// Create the default material.
    public static var `default`: Material = {
        Material(name: "default", renderMode: .opaque,
                 albedoTexture: nil, normalTexture: nil, roughnessMetalnessOcclusionTexture: nil, emissionTexture: nil,
                 albedo: [0.5,0.5,0.5], roughness: 1, metalness: 0, emission: float3.zero,
                 alphaCutoff: 0.2, alpha: 1,
                 doubleSided: false)
    }()
}
