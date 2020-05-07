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
    case None
    case Color(SIMD4<Float>)
    case Texture(Int)
}

enum SAAlphaMode: UInt8 {
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
            self = SAMaterialProperty.None
        case 1:
            let color = try container.decode(SIMD4<Float>.self)
            self = SAMaterialProperty.Color(color)
        case 2:
            let texture = try container.decode(Int.self)
            self = SAMaterialProperty.Texture(texture)
        default:
            throw CodingError.unknownValue
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
        case .None:
            try container.encode(UInt8(0))
        case .Color(let color):
            try container.encode(UInt8(1))
            try container.encode(color)
        case .Texture(let texture):
            try container.encode(UInt8(2))
            try container.encode(texture)
        }
    }
}

extension SAAlphaMode: Codable {
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
       case unknownValue
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let rawValue = try container.decode(UInt8.self)
        
        guard let value = SAAlphaMode(rawValue: rawValue) else {
            throw CodingError.unknownValue
        }
        
        self = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.rawValue)
    }
}
