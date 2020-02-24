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
    
    
    
    
    func render(renderEncoder: MTLRenderCommandEncoder, pass: RenderPass, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms) {
        guard let mesh = get(component: MeshSelector.self)?.mesh,
            let transform = self.transform else {
            return
        }

//        print("[MeshRenderer] Render mesh \(mesh.name)")
        
        mesh.render(renderEncoder: renderEncoder, pass: pass, vertexUniforms: vertexUniforms, fragmentUniforms: fragmentUniforms, worldTransform: transform.worldTransform)
    }
}
