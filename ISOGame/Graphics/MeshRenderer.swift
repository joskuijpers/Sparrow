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
    
    /// Add renderables to render set
    func renderQueue(set: RenderSet, frustum: Frustum, viewPosition: float3) {
        guard let mesh = get(component: MeshSelector.self)?.mesh,
            let transform = self.transform else {
            return
        }
        
        let wt = transform.worldTransform
        let bounds = mesh.bounds * wt
        DebugRendering.shared.box(min: bounds.minBounds, max: bounds.maxBounds, color: [1,0,0])
        

        if frustum.intersects(bounds: bounds) == .outside {
            return
        }
        
        // If shadow pass and does not cast shadows: skip
        
        
        // if mesh.bounds inside frustum
        mesh.addToRenderSet(set: set, pass: .geometry, viewPosition: viewPosition, worldTransform: wt)
    }
}
