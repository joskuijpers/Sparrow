//
//  RenderMesh.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowECS

/// The mesh render mode.
enum RenderMode {
    /// Opaque. Pixels always show.
    case opaque
    /// Alpha testing. Pixels either show or do not show.
    case cutOut
    /// Translucency, also named alpha blending. Pixels can have partial alpha.
    case translucent
}

/**
 Renders meshes inserted by MeshSelector.
 */
final class RenderMesh: Component {
    public var mesh: Mesh?

    public let castShadows: Bool = false
    public let receiveShadows: Bool = false
    
    // enabled (Renderer)
    
    /// Init with a mesh
    init(mesh: Mesh) {
        self.mesh = mesh
    }
}
