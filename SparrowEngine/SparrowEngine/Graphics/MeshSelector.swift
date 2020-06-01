//
//  MeshSelector.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowECS

/**
 Selects a mesh
 */
final class MeshSelector: Component {
    public var mesh: Mesh?
    
    /// Init with a mesh
    init(mesh: Mesh) {
        self.mesh = mesh
    }
}
