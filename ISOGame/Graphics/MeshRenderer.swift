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
    func renderQueue(set: RenderSet, frustrum: Frustrum, viewPosition: float3) {
        guard let mesh = get(component: MeshSelector.self)?.mesh,
            let transform = self.transform else {
            return
        }
        
        let bounds = mesh.bounds * transform.worldTransform
        DebugRendering.shared.box(min: bounds.minBounds, max: bounds.maxBounds, color: [1,0,0])
        
        let wt = transform.worldTransform
        if frustrum.intersects(bounds: mesh.bounds * wt) == .outside {
            return
        }
        
        // If shadow pass and does not cast shadows: skip
        
        
        // if mesh.bounds inside frustrum
        mesh.addToRenderSet(set: set, pass: .geometry, viewPosition: viewPosition, worldTransform: wt)
    }
}
