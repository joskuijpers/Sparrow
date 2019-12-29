//
//  DataStructure.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

struct JSONRoot: Codable {
    var asset: JSONAsset
    var scene: Int?
    var scenes: [JSONScene]?
    var nodes: [JSONNode]?
    var accessors: [JSONAccessor]?
    var materials: [JSONMaterial]?
    var buffers: [JSONBuffer]?
    var bufferViews: [JSONBufferView]?
    var textures: [JSONTexture]?
    var samplers: [JSONSampler]?
    var images: [JSONImage]?
    var cameras: [JSONCamera]?
    var meshes: [JSONMesh]?
    
    var extensionsUsed: [String]?
    var extensionsRequired: [String]?
//    var extensions
//    var extras
}

struct JSONAsset: Codable {
    var version: String
    
    var generator: String?
    var minVersion: String?
    var copyright: String?
    
//    var extensions: Any?
//    var extras: Any?
}

struct JSONScene: Codable {
    var nodes: [Int]?
    var name: String?
    
    //    var extensions: Any?
    //    var extras: Any?
}

struct JSONNode: Codable {
    var camera: Int?
    var skin: Int?
    var children: [Int]?
    var matrix: [Float]?
    var mesh: Int?
    var rotation: [Float]?
    var scale: [Float]?
    var translation: [Float]?
    var weights: [Float]?
    
    var name: String?
//    var extensions
//    var extras
}

struct JSONMesh: Codable {
    var primitives: [JSONPrimitive]
    var weights: [Float]?
    var name: String?
    //    var extensions
    //    var extras
}

struct JSONPrimitive: Codable {
    var attributes: [String : Int] // POSITION VEC3 FLOAT, NORMAL VEC3 FLOAT, TANGENT VEC4 FLOAT, TEXCOORD_1 VEC2 FLOAT/UBYTE/USHORT, TEXCOORD_2 VEC2 FLOAT/UBYTE/USHORT, COLOR_0 VEC3/VEC4 FLOAT/UBYTE/USHORT, JOINTS_0 VEC4, WEIGHTS_0 VEC4
    // position must have min and max defined
    // can support more than 1 vertex color, must support at least 2 texture coord sets
    
    var indices: Int? // if defined, use indixed draw mode
    
    var mode: Int? = 4
    var material: Int?
//    var targets: morhtarget
    
//    var targets morph targets
    
    //    var extensions
    //    var extras
}

struct JSONAccessor: Codable {
    var bufferView: Int?
    var byteOffset: Int? = 0
    
    var componentType: Int // 5120 byte, 5121 ubyte, 5122 short, 5123 ushort, 5125 uint, 5126 float
    var count: Int
    var type: String // SCALAR (1), VEC2 2, VEC3 3, VEC4 4, MAT2 4, MAT3 9, MAT4 16
    
    var max: [Float]?
    var min: [Float]?
    // var sparse
    var name: String?
//    var extensions
//    var extras
    
}

struct JSONMaterial: Codable {
    var name: String?
    
    var pbrMetallicRoughness: JSONMaterial.JSONPBR?
    
    var normalTexture: JSONMaterial.NormalTextureInfo? // RGB
    var emissiveTexture: JSONMaterial.TextureInfo? // RGB
    var occlusionTexture: JSONMaterial.OcclusionTextureInfo? // R
    
    /// Emissive color
    var emissiveFactor: [Float]?
    var alphaMode: String? = "OPAQUE"
    var alphaCutoff: Float? = 0.5
    var doubleSided: Bool? = false
    
//    var extensions
//    var extras
    
    struct JSONPBR: Codable {
        var baseColorFactor: [Float]? = [1, 1, 1, 1]
        var metallicFactor: Float? = 1
        var roughnessFactor: Float? = 1
        
        var baseColorTexture: JSONMaterial.TextureInfo?
        var metallicRoughnessTexture: JSONMaterial.TextureInfo? // G=roughness, B=metalness
        
        //    var extensions
        //    var extras
    }
    
    struct NormalTextureInfo: Codable {
        var index: Int
        var texCoord: Int? = 0
        var scale: Float? = 1
        
        //    var extensions
        //    var extras
    }
    
    struct OcclusionTextureInfo: Codable {
        var index: Int
        var texCoord: Int? = 0
        var strength: Float? = 1
        
        //    var extensions
        //    var extras
    }
    
    struct TextureInfo: Codable {
        var index: Int
        var texCoord: Int?

        //    var extensions
        //    var extras
    }
}

struct JSONBufferView: Codable {
    var buffer: Int
    var byteOffset: Int = 0
    var byteLength: Int
    
    var target: Int?
    var byteStride: Int?
    
    var name: String?
        
    //    var extensions
    //    var extras
}

struct JSONBuffer: Codable {
    var byteLength: Int
    var uri: String? // URI
    var name: String?
    
//    var extensions
//    var extras
    
    // type
    // data let decodedData = Data(base64Encoded: data.convertToData())
}

struct JSONTexture: Codable {
    var sampler: Int?
    var source: Int? // image
    var name: String?
    //    var extensions
    //    var extras
}

struct JSONImage: Codable {
    var uri: String? // URI
    var bufferView: Int?
    var mimeType: String?
    var name: String?
    
//    var extensions
//    var extras
    
    func isValid() -> Bool {
        return uri != nil || (bufferView != nil && mimeType != nil)
    }
    
    // 0,0 is left-upper corner
}

struct JSONSampler: Codable {
//    9728 NEAREST
//    9729 LINEAR
    var magFilter: Int?
    
//    9728 NEAREST
//    9729 LINEAR
//    9984 NEAREST_MIPMAP_NEAREST
//    9985 LINEAR_MIPMAP_NEAREST
//    9986 NEAREST_MIPMAP_LINEAR
//    9987 LINEAR_MIPMAP_LINEAR
    var minFilter: Int?
    
//    33071 CLAMP_TO_EDGE
//    33648 MIRRORED_REPEAT
//    10497 REPEAT
    var wrapS: Int?
    
//    33071 CLAMP_TO_EDGE
//    33648 MIRRORED_REPEAT
//    10497 REPEAT
    var wrapT: Int?
    
    var name: String?
    
    //    var extensions
    //    var extras
}

struct JSONCamera: Codable {
    var name: String?
    var type: String // perspective, orthographic
    var perspective: JSONCamera.Perspective?
    var orthographic: JSONCamera.Orthographic?
    
    //    var extensions
    //    var extras
    
    struct Perspective: Codable {
        var aspectRatio: Float?
        var yfov: Float
        var zfar: Float?
        var znear: Float
        
        //    var extensions
        //    var extras
    }
    
    struct Orthographic: Codable {
        var xmag: Float
        var ymag: Float
        var zfar: Float
        var znear: Float
        
        //    var extensions
        //    var extras
    }
}
