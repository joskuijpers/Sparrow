//
//  MeshRenderer.swift
//  ISOGame
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
final class MeshRenderer: Component {
    
    let castShadows: Bool = false
    let receiveShadows: Bool = false
    
//    localToWorldMatrix (ro) (Renderer)
//    worldToLocalMatrix (ro) (Renderer)
    // bounds
    // enabled (Renderer)
}
