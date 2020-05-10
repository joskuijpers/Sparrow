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
    public let name: String
    
    public let albedo: SAMaterialProperty
    public let normals: SAMaterialProperty
    public let roughnessMetalnessOcclusion: SAMaterialProperty
    public let emissive: SAMaterialProperty
//
//    @property (nonatomic, assign) simd_float4 baseColorFactor;
//    @property (nonatomic, assign) float metalnessFactor;
//    @property (nonatomic, assign) float roughnessFactor;
//    @property (nonatomic, assign) float normalTextureScale;
//    @property (nonatomic, assign) float occlusionStrength;
//    @property (nonatomic, assign) simd_float3 emissiveFactor;

//    @property (nonatomic, strong) GLTFTextureInfo * _Nullable baseColorTexture;
//    @property (nonatomic, strong) GLTFTextureInfo * _Nullable metallicRoughnessTexture;
//    @property (nonatomic, strong) GLTFTextureInfo * _Nullable normalTexture;
//    @property (nonatomic, strong) GLTFTextureInfo * _Nullable emissiveTexture;
//    @property (nonatomic, strong) GLTFTextureInfo * _Nullable occlusionTexture;
    
    public let alphaMode: SAAlphaMode
    public let alphaCutoff: Float
    
    public init(name: String,
                albedo: SAMaterialProperty,
                normals: SAMaterialProperty,
                roughnessMetalnessOcclusion: SAMaterialProperty,
                emissive: SAMaterialProperty,
                alphaMode: SAAlphaMode,
                alphaCutoff: Float) {
        self.name = name
        self.albedo = albedo
        self.normals = normals
        self.roughnessMetalnessOcclusion = roughnessMetalnessOcclusion
        self.emissive = emissive
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

public enum SAAlphaMode: UInt8, BinaryCodable {
    case opaque
    case mask
    case blend
}

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
