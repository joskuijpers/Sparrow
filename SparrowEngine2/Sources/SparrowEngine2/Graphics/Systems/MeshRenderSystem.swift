//
//  MeshRenderSystem.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 11/06/2020.
//

import SparrowECS

final class MeshRenderSystem: System {
    let meshes: Group<Requires2<Transform, RenderMesh>>
    
    init(world: World) {
        meshes =  world.nexus.group(requiresAll: Transform.self, RenderMesh.self)
    }
    
    /// Build the render queue by filling it with the appropriate meshes
    func buildQueue(set: RenderSet, renderPass: RenderPass, frustum: Frustum, viewPosition: float3) {
        for (transform, renderer) in meshes {
            guard let mesh = renderer.mesh else {
                continue
            }
            
            if renderPass == .shadows && !renderer.castShadows {
                continue
            }
            
            mesh.addToRenderSet(set: set,
                                viewPosition: viewPosition,
                                worldTransform: transform.localToWorldMatrix,
                                frustum: frustum)
        }
    }
}
