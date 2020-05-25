//
//  SAMaterial.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 01/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import simd
import SparrowBinaryCoder

/// A material.
public struct SAMaterial: BinaryCodable {
    /// Name of the material. Might not be unique.
    public let name: String
    
    /// Albedo (base color) property.
    public let albedo: SAMaterialProperty
    
    /// Normals property. Normals are in tangent space.
    public let normals: SAMaterialProperty
    
    /// Roughness/metalness/occlusion property. The red channel is roughness, metalness is in green and occlusion in blue.
    public let roughnessMetalnessOcclusion: SAMaterialProperty
    
    /// Emission property. All zeroes has no emission.
    public let emission: SAMaterialProperty

//    @property (nonatomic, assign) simd_float4 baseColorFactor;
//    @property (nonatomic, assign) float metalnessFactor;
//    @property (nonatomic, assign) float roughnessFactor;
//    @property (nonatomic, assign) float normalTextureScale;
//    @property (nonatomic, assign) float occlusionStrength;
//    @property (nonatomic, assign) simd_float3 emissiveFactor;
    
    /// Alpha mode, decides render mode and whether blending is active.
    public let alphaMode: SAAlphaMode
    
    /// Alpha cutoff value.
    public let alphaCutoff: Float
    
    public init(name: String,
                albedo: SAMaterialProperty,
                normals: SAMaterialProperty,
                roughnessMetalnessOcclusion: SAMaterialProperty,
                emission: SAMaterialProperty,
                alphaMode: SAAlphaMode,
                alphaCutoff: Float) {
        self.name = name
        self.albedo = albedo
        self.normals = normals
        self.roughnessMetalnessOcclusion = roughnessMetalnessOcclusion
        self.emission = emission
        self.alphaMode = alphaMode
        self.alphaCutoff = alphaCutoff
    }
}

/// A material property
public enum SAMaterialProperty {
    case none
    case color(SIMD4<Float>)
    case texture(Int)
}

/// Alpha mode of the renderable.
public enum SAAlphaMode: UInt8, BinaryCodable {
    /// The mesh is opaque. Depth testing applies to the whole mesh.
    case opaque
    
    /// The albedo texture contains an alpha channel that masks whether a pixel is visible.
    case mask
    
    /// Alpha blending is applied
    case blend
}

// Due to associated values, the material property needs a custom encoder and decoder.
extension SAMaterialProperty: BinaryCodable {
    enum CodingError: Error {
       case unknownValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(UInt8.self)
        
        switch type {
        case 0:
            self = SAMaterialProperty.none
        case 1:
            let color = try container.decode(SIMD4<Float>.self)
            self = SAMaterialProperty.color(color)
        case 2:
            let texture = try container.decode(Int.self)
            self = SAMaterialProperty.texture(texture)
        default:
            throw CodingError.unknownValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
        case .none:
            try container.encode(UInt8(0))
        case .color(let color):
            try container.encode(UInt8(1))
            try container.encode(color)
        case .texture(let texture):
            try container.encode(UInt8(2))
            try container.encode(texture)
        }
    }
}
