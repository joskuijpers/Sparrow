//
//  SPMMaterial.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 01/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import simd
import SparrowBinaryCoder

/// A material.
public struct SPMMaterial: BinaryCodable {
    /// Name of the material. Might not be unique.
    public let name: String
    
    /// Albedo (base color) property.
    public let albedo: SPMMaterialProperty
    
    /// Normals property. Normals are in tangent space.
    public let normals: SPMMaterialProperty
    
    /// Roughness/metalness/occlusion property. The red channel is roughness, metalness is in green and occlusion in blue.
    public let roughnessMetalnessOcclusion: SPMMaterialProperty
    
    /// Emission property. All zeroes has no emission.
    public let emission: SPMMaterialProperty

//    @property (nonatomic, assign) simd_float4 baseColorFactor;
//    @property (nonatomic, assign) float metalnessFactor;
//    @property (nonatomic, assign) float roughnessFactor;
//    @property (nonatomic, assign) float normalTextureScale;
//    @property (nonatomic, assign) float occlusionStrength;
//    @property (nonatomic, assign) simd_float3 emissiveFactor;
    
    /// Alpha mode, decides render mode and whether blending is active.
    public let alphaMode: SPMAlphaMode
    
    /// Alpha cutoff value.
    public let alphaCutoff: Float
    
    /// Whether the material should be rendered from front and backside.
    public let doubleSided: Bool
    
    /// Create a material.
    public init(name: String,
                albedo: SPMMaterialProperty,
                normals: SPMMaterialProperty,
                roughnessMetalnessOcclusion: SPMMaterialProperty,
                emission: SPMMaterialProperty,
                alphaMode: SPMAlphaMode,
                alphaCutoff: Float,
                doubleSided: Bool) {
        self.name = name
        self.albedo = albedo
        self.normals = normals
        self.roughnessMetalnessOcclusion = roughnessMetalnessOcclusion
        self.emission = emission
        self.alphaMode = alphaMode
        self.alphaCutoff = alphaCutoff
        self.doubleSided = doubleSided
    }
}

/// A material property
public enum SPMMaterialProperty {
    /// There is no value.
    case none
    /// A vector value, often interpreted as a color.
    case color(SIMD4<Float>)
    /// A texture should be used.
    case texture(Int)
}

/// Alpha mode of the renderable.
public enum SPMAlphaMode: UInt8, BinaryCodable {
    /// The mesh is opaque. Depth testing applies to the whole mesh.
    case opaque
    
    /// The albedo texture contains an alpha channel that masks whether a pixel is visible.
    case mask
    
    /// Alpha blending is applied
    case blend
}

// Due to associated values, the material property needs a custom encoder and decoder.
extension SPMMaterialProperty: BinaryCodable {
    enum CodingError: Error {
        /// The value is not known.
        case unknownValue
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(UInt8.self)
        
        switch type {
        case 0:
            self = SPMMaterialProperty.none
        case 1:
            let color = try container.decode(SIMD4<Float>.self)
            self = SPMMaterialProperty.color(color)
        case 2:
            let texture = try container.decode(Int.self)
            self = SPMMaterialProperty.texture(texture)
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
