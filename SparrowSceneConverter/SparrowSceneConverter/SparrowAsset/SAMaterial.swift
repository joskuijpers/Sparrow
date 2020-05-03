//
//  SAMaterial.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 01/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

enum SAAlphaMode {
    case opaque
    case mask
    case blend
}

/// A material.
struct SAMaterial {
    var name: String
    
    var albedo: SAMaterialProperty
    var normals: SAMaterialProperty
    var metalnessRoughnessOcclusion: SAMaterialProperty
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
    case Texture(Int)
    case Color(SIMD4<Float>)
    case None
}
