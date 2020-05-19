//
//  MeshLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 19/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 Loader of meshes.
 
 Gives fully built meshes. Might re-use resources when possible.
 */
class MeshLoader {
    private let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    /**
     Load a mesh with given name.
     */
    func load(name: String) throws -> Mesh {
        print("LOAD MESH FOR \(name)")
        
        let m = try Mesh(name: name)
        return m
    }
}
