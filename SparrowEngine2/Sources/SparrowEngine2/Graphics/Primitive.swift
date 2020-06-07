//
//  Primitive.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal

public struct Primitive {
    
    /// Cube with given edge size.
    @inlinable
    public static func cube(device: MTLDevice, size: Float) { // -> Mesh
        return box(device: device, size: float3(size, size, size))
    }
    
    /// A box with given edge sizes.
    public static func box(device: MTLDevice, size: float3) { // -> Mesh
    }
    
    /// A sphere mesh with a radius.
    public static func sphere(device: MTLDevice, radius: Float) { // -> Mesh
    }
    
    /// A plane mesh with size on X and Z axes.
    public static func plane(device: MTLDevice, size: float2) { // -> Mesh
    }
    
}
