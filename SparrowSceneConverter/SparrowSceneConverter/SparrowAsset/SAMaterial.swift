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
struct SAMaterial {
    var name: String
    
    var albedo: SAMaterialProperty
    var normals: SAMaterialProperty
    var metalnessRoughnessOcclusion: SAMaterialProperty
    var emissive: SAMaterialProperty
    
    var blendMode: Int
    var alphaMode: Int
}

/// A material property
enum SAMaterialProperty {
    case Texture(URL)
    case Color(SIMD4<Float>)
    case None
}

extension SAMaterialProperty: CustomStringConvertible {
    var description: String {
        switch self {
        case .Texture(let url): return "\(url.path)"
        case .Color(let value): return "\(value)"
        case .None: return "none"
        }
    }
}
