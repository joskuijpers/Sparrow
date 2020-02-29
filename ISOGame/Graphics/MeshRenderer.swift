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
    
    
    func render(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms) {
        guard let mesh = get(component: MeshSelector.self)?.mesh,
            let transform = self.transform else {
            return
        }

//        print("[MeshRenderer] Render mesh \(mesh.name)")
        
        mesh.render(renderEncoder: renderEncoder, pass: .gbuffer, vertexUniforms: vertexUniforms, fragmentUniforms: fragmentUniforms, worldTransform: transform.worldTransform)
    }
    
    // Render into the queue
    // TODO: create Frustrum type
    func renderQueue(set: RenderSet, frustrum: Bool, viewPosition: float3) {
        guard let mesh = get(component: MeshSelector.self)?.mesh,
            let transform = self.transform else {
            return
        }
        
        // if mesh.bounds inside frustrum
        mesh.addToRenderSet(set: set, pass: .gbuffer, viewPosition: viewPosition, worldTransform: transform.worldTransform)
    }
}
