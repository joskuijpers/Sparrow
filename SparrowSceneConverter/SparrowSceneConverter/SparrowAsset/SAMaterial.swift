//
//  SAMaterial.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 01/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

/// A material.
struct SAMaterial: Codable {
    var name: String
    
    var albedo: SAMaterialProperty
    var normals: SAMaterialProperty
    var roughnessMetalnessOcclusion: SAMaterialProperty
    var emissive: SAMaterialProperty
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
    
    var alphaMode: SAAlphaMode
    var alphaCutoff: Float
}

/// A material property
enum SAMaterialProperty {
    case none
    case color(SIMD4<Float>)
    case texture(Int)
}

enum SAAlphaMode: UInt8, Codable {
    case opaque
    case mask
    case blend
}

extension SAMaterialProperty: Codable {
    enum CodingError: Error {
       case unknownValue
    }
    
    init(from decoder: Decoder) throws {
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
    
    func encode(to encoder: Encoder) throws {
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
