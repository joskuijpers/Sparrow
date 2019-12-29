//
//  MathLibrary.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

extension float4x4 {
    init(array: [Float]) {
        guard array.count == 16 else {
            fatalError("Presented array has \(array.count) elements but 16 elements are required")
        }
        
        self = matrix_identity_float4x4
        
        columns = (
            float4( array[0],  array[1],  array[2],  array[3]),
            float4( array[4],  array[5],  array[6],  array[7]),
            float4( array[8],  array[9],  array[10], array[11]),
            float4( array[12],  array[13],  array[14],  array[15])
        )
    }
    
    init(translation: float3) {
        self = matrix_identity_float4x4
        columns.3.x = translation.x
        columns.3.y = translation.y
        columns.3.z = translation.z
    }
    
    init(scaling: float3) {
        self = matrix_identity_float4x4
        columns.0.x = scaling.x
        columns.1.y = scaling.y
        columns.2.z = scaling.z
    }
}

extension SIMD3 {
    init(array: [Scalar]) {
        guard array.count == 3 else {
            fatalError("float3 array has \(array.count) elements - a float3 needs 3 elements")
        }
        
        self = SIMD3<Scalar>(array[0], array[1], array[2])
    }
}

extension SIMD4 {
    init(array: [Scalar]) {
        guard array.count == 4 else {
            fatalError("float4 array has \(array.count) elements - a float4 needs 4 elements")
        }
        
        self = SIMD4<Scalar>(array[0], array[1], array[2], array[3])
    }
}

extension simd_quatf {
    init(array: [Float]) {
        guard array.count == 4 else {
            fatalError("quaternion array has \(array.count) elements - a quaternion needs 4 Floats")
        }
        
        self = simd_quatf(ix: array[0], iy: array[1], iz: array[2], r: array[3])
    }
}
