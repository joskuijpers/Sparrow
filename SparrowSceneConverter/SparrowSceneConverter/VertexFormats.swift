//
//  VertexFormats.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 28/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd


fileprivate protocol Vertex: Hashable {
}

/// A vertex with position,normals and texture coordinates
struct TexturedVertex: Vertex {
    let x: Float
    let y: Float
    let z: Float
    
    let nx: Float
    let ny: Float
    let nz: Float
    
    let u: Float
    let v: Float
}

/// A vertex with position,normals, tangents and texture coordinates
struct TexturedTangentVertex: Vertex {
    let x: Float
    let y: Float
    let z: Float
    
    let nx: Float
    let ny: Float
    let nz: Float
    
    let tx: Float
    let ty: Float
    let tz: Float

    let btx: Float
    let bty: Float
    let btz: Float
    
    let u: Float
    let v: Float
}
