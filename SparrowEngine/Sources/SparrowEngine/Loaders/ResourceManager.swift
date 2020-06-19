//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 17/06/2020.
//

import Foundation

//??????

// load texture
    // cache
// load mesh
    // cache but write protection? allow copy? or copy with buffers but new material?
// make buffer
    // copy buffer? write protect?
// load scene

/// Path of a resource
public typealias ResourcePath = String

public final class ResourceManager {
    /// A list of all loaded meshes that have not changed from their file system state.
    private var meshes: [ResourcePath:Mesh] = [:]
    
    init() {
        
    }
    
    /// Load a mesh at a resource path
    ///
    /// If the mesh was already loaded it will give the same instance.
    public func loadMesh(resourcePath: ResourcePath) throws -> Mesh {
        if let mesh = meshes[resourcePath] {
            return mesh
        }
        
        // TODO FIX. Cannot move to init because device doesn not exist yet
        let device = World.shared!.graphics.device
        let meshLoader = MeshLoader(device: device, textureLoader: TextureLoader(device: device))
        
        let mesh = try meshLoader.load(url: Self.url(for: resourcePath))
        
        // Store in list of known meshes
        meshes[resourcePath] = mesh
        
        return mesh
    }
    
    func resourcePathFor(mesh: Mesh) -> ResourcePath? {
         return "ironSphere/ironSphere.spmesh"
//        return nil
    }
    
    // When a mesh changes material, it has to be duplicated _if in the resource manager_
    // If the mesh is not in the resource manager it is already unshared. We can mark it
    // shared=true/false in the Mesh
    
    // isUniquelyReferenced
    // can also set material on _all_ instances so then we dont duplicate...
    //
    
    
    
    
    
    
    
    /// URL for the resources folder
    private static var resourceUrl: URL {
        return Bundle.main.resourceURL!.appendingPathComponent("Assets")
    }
    
    /// Path for given asset. If asset does not exist, returns nil
    public static func url(for resourcePath: ResourcePath) -> URL {
        print("GET PATH \(resourcePath)")
        return Self.resourceUrl.appendingPathComponent(resourcePath).absoluteURL
    }
    
    /// Shortest name for the object at given URL
    public static func resourcePath(for url: URL) -> ResourcePath {
        let rp = Self.resourceUrl.path
        if url.path.hasPrefix(rp) {
            return "res:///" + String(url.path.dropFirst(rp.count + 1)) // +1 for the /
        } else {
            return "res:///" + url.path
        }
    }
}
