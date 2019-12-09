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
    class func cube(device: MTLDevice, size: Float) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false,
                           geometryType: .triangles,
                           allocator: allocator)
        
        return mesh
    }
    
    class func sphere(device: MTLDevice) -> MDLMesh {
      let allocator = MTKMeshBufferAllocator(device: device)
      let newSphere = MDLMesh(sphereWithExtent: [1,1,1],
                              segments: [10,10],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
      return newSphere
    }
    
    class func plane(device: MTLDevice) -> MDLMesh {
      let allocator = MTKMeshBufferAllocator(device: device)
      let newPlane = MDLMesh.newPlane(withDimensions: [100, 100],
                                      segments: [1, 1],
                                      geometryType: .triangles,
                                      allocator: allocator)
      return newPlane
    }
    
}
