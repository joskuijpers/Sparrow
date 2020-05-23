//
//  ObjTypes.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

struct ObjFile {
    var mtllib: String?
    
    var positions: [float3] = []
    var normals: [float3] = []
    var texCoords: [float2] = []
    var submeshes: [ObjSubmesh] = []
}

struct MtlFile {
    var materials: [MtlMaterial] = []
}

struct MtlMaterial {
    let name: String
    
    var albedoColor: float3 = float3(1, 0, 1) // Violet
    var roughness: Float = 1 // Fully rought
    var metallic: Float = 0 // Fully dielectric
    var alpha: Float = 1 // No opacity
    var emissiveColor: float3 = float3(0, 0, 0) // No emission
    
    var albedoTexture: URL?
    var normalTexture: URL?
    var roughnessTexture: URL?
    var metallicTexture: URL?
    var aoTexture: URL?
    var emissiveTexture: URL?
    var alphaTexture: URL?
    var hasAlpha = false
}

struct ObjFace {
    var vertIndices: [Int]
}

struct ObjVertex {
    var position: Int
    var normal: Int
    var texCoord: Int
    var tangent: float3 = float3(0, 0, 0)
    var bitangent: float3 = float3(0, 0, 0)
}

struct ObjSubmesh {
    let name: String
    let material: String?
    let faces: [ObjFace]
    let vertices: [ObjVertex]
}
