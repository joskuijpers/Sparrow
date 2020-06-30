//
//  RenderMesh.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowECS

/// Renders meshes inserted by MeshSelector.
public final class RenderMesh: Component {
    /// The mesh to render
    public var mesh: Mesh?
    
    /// Materials to use for each submesh in the mesh.
    public var materials: [Material]?

    /// Whether the mesh casts shadows
    public var castShadows: Bool = false
    
    /// Whether the mesh received shadows
    public var receiveShadows: Bool = false
    
    // enabled (Renderer)
    
    /// Mesh resource name: used for coding.
    private var meshResource: String? = nil

    /// Init with a mesh
    public init(mesh: Mesh) {
        self.mesh = mesh
    }
    
    /// Init with a mesh and materials
    public init(mesh: Mesh, materials: [Material]) {
        self.mesh = mesh
        self.materials = materials
    }
    
    public override init() {
        self.mesh = nil
    }

}

extension RenderMesh: Storable, ComponentStorageDelegate {

    // Omit the mesh parameter
    private enum CodingKeys: String, CodingKey {
        case castShadows, receiveShadows
        case meshResource
    }
    
    public func willEncode(from world: World) throws {
        if let mesh = mesh {
            meshResource = world.resourceManager.resourcePathFor(mesh: mesh)
        } else {
            meshResource = nil
        }
    }

    public func didDecode(into world: World) throws {
        if let meshResource = meshResource {
            mesh = try world.resourceManager.loadMesh(resourcePath: meshResource)
        } else {
            mesh = nil
        }
    }
}
