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

    /// Whether the mesh casts shadows
    public let castShadows: Bool = false
    
    /// Whether the mesh received shadows
    public let receiveShadows: Bool = false
    
    // enabled (Renderer)
    
    /// Init with a mesh
    public init(mesh: Mesh) {
        self.mesh = mesh
    }
}
