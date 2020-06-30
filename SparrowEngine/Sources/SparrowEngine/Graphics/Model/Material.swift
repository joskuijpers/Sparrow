//
//  Material.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 21/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/*
 This whole struct needs a lot of work.
 Do we want to allow changes? We should keep the number of materials to a minimum
 so using a class and shared/unshared materials might be a good idea.
 
 Then using a var everywhere and marking as dirty might be a good idea as well
 as it allows changing the material at runtime.
 If dirty it would need a new pipeline.
 
 We should store a list of generated materials somewhere and keep an ID so we
 can easily sort. Or we sort on pointer which would work without extra steps.
 
 */

/// A graphical material.
public final class Material {
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
    
    /// Create the default material.
    public static var `default`: Material = {
        Material(name: "default", renderMode: .opaque,
                 albedoTexture: nil, normalTexture: nil, roughnessMetalnessOcclusionTexture: nil, emissionTexture: nil,
                 albedo: [1,0.5,0.5], roughness: 1, metalness: 0, emission: float3.zero,
                 alphaCutoff: 0.2, alpha: 1,
                 doubleSided: false)
    }()
}
