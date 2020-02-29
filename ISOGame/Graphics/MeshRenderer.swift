//
//  MeshRenderer.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import Metal

class MeshRenderer: Component {
    
    // castShadows: Bool
    // receiveShadows: Bool
    
    // Render into the queue
    // TODO: create Frustrum type
    func renderQueue(set: RenderSet, frustrum: Bool, viewPosition: float3) {
        guard let mesh = get(component: MeshSelector.self)?.mesh,
            let transform = self.transform else {
            return
        }
        
        // if mesh.bounds inside frustrum
        mesh.addToRenderSet(set: set, pass: .geometry, viewPosition: viewPosition, worldTransform: transform.worldTransform)
    }
}
