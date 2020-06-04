//
//  Mesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal
import SparrowEngine2

/**
 A mesh.
 
 Contains submeshes and other info needed for rendering.
 */
class Mesh {
    /// Name of the mesh. Usefull for debugging
    public let name: String
    
    /// Bounds of the mesh
    public let bounds: Bounds
    
    /// List of submeshes
    public let submeshes: [Submesh]
    
    /// Vertex and index buffers
    let buffers: [MTLBuffer]
    
    /// Vertex format descriptor
    let vertexDescriptor: MTLVertexDescriptor

    /// Initialize a new mesh. This is called from Meshloader only.
    init(name: String, bounds: Bounds, buffers: [MTLBuffer], vertexDescriptor: MTLVertexDescriptor, submeshes: [Submesh]) {
        self.name = name
        self.bounds = bounds
        self.buffers = buffers
        self.vertexDescriptor = vertexDescriptor
        self.submeshes = submeshes
    }
}

// MARK: - Rendering

extension Mesh {
    /// Ask the mesh to add to the render set if within frustum.
    @inlinable
    func addToRenderSet(set: RenderSet, viewPosition: float3, worldTransform: float4x4, frustum: Frustum) {
        let bounds = self.bounds * worldTransform
        if frustum.intersects(bounds: bounds) == .outside {
            // Mesh is not in frustum
            return
        }
        
        for (index, submesh) in submeshes.enumerated() {
            submesh.addToRenderSet(set: set, viewPosition: viewPosition, worldTransform: worldTransform, frustum: frustum, mesh: self, submeshIndex: index)
        }
    }
    
    /// Render the submesh at given index.
    func render(renderEncoder: MTLRenderCommandEncoder, renderPass: RenderPass, uniforms: Uniforms, submeshIndex: UInt16, worldTransform: float4x4) {
        // Set model vertex uniforms
        var uniforms = uniforms
        uniforms.modelMatrix = worldTransform
        uniforms.normalMatrix = worldTransform.upperLeft

        renderEncoder.setVertexBytes(&uniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))

        // Set model vertex buffers
        for index in 0..<buffers.count {
            renderEncoder.setVertexBuffer(buffers[index], offset: 0, index: index)
        }
        
        let submesh = submeshes[Int(submeshIndex)]
        submesh.render(renderEncoder: renderEncoder, renderPass: renderPass, buffers: buffers)
    }
}
