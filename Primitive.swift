//
//  Primitive.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Primitive {
    
    /**
     Create a simple cube model
     */
    static func makeCube(device: MTLDevice, size: Float) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false,
                           geometryType: .triangles,
                           allocator: allocator)
        
        return mesh
    }
    
    static func makeSphere(device: MTLDevice, radius: Float) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(sphereWithExtent: [radius, radius, radius],
                           segments: [25, 25],
                           inwardNormals: false,
                           geometryType: .triangles,
                           allocator: allocator)
        return mesh
    }
    
}
