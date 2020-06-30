//
//  Submesh.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 A submesh uses the vertex buffer from a mesh with its own index buffer. It has a single material.
 */
public struct Submesh {
    /// Name of the submesh for debugging
    public let name: String
    
    /// Submesh bounds. Used for culling.
    public let bounds: Bounds

    /// Info on the index buffer
    struct IndexBufferInfo {
        /// Index in the buffer list of the mesh
        let bufferIndex: Int
        
        /// Byte-offset into the buffer
        let offset: Int
        
        /// Num indices in this buffer.
        let numIndices: Int
        
        /// Format of an index
        let indexType: MTLIndexType
    }
    
    /// Info on the index buffer
    let indexBufferInfo: IndexBufferInfo
    
    /// Initialize a new submesh. This is called from Meshloader only.
    init(name: String, bounds: Bounds, indexBufferInfo: IndexBufferInfo) {
        self.name = name
        self.bounds = bounds
        self.indexBufferInfo = indexBufferInfo
    }
}

// MARK: - Rendering
extension Submesh {
    /// Ask the mesh to add to the render set if within frustum.
    func addToRenderSet(set: RenderSet, viewPosition: float3, worldTransform: float4x4, frustum: Frustum, mesh: Mesh, submeshIndex: Int, pipelineState: MetalSubmeshPipelineState, material: Material) {
        let bounds = self.bounds * worldTransform
        if frustum.intersects(bounds: bounds) == .outside {
            // Submesh is not in frustum
            return
        }

        // Calculate approximate depth, used for render sorting
        let depth: Float = distance(viewPosition, bounds.center)

//        set.add(material.renderMode) { item in
        set.add(.opaque) { item in
            item.depth = depth
            item.mesh = mesh
            item.submeshIndex = UInt16(submeshIndex)
            item.worldTransform = worldTransform
            item.pipelineState = pipelineState
            item.material = material
        }
    }
    
    /// Render the submesh. Mesh-wide state is already set.
    func render(renderEncoder: MTLRenderCommandEncoder,
                renderPass: RenderPass,
                buffers: [MTLBuffer],
                pipelineState: MetalSubmeshPipelineState,
                material: Material) {
        let useDepthOnly = (renderPass == .depthPrePass || renderPass == .shadows) && pipelineState.depthPipelineState != nil
        if useDepthOnly {
            renderEncoder.setRenderPipelineState(pipelineState.depthPipelineState!)
        } else {
            renderEncoder.setRenderPipelineState(pipelineState.pipelineState)
        }
        
        // Set textures
        if useDepthOnly && material.renderMode == .cutOut {
            renderEncoder.setFragmentTexture(material.albedoTexture, index: Int(TextureAlbedo.rawValue))
        }

        if !useDepthOnly {
            renderEncoder.setFragmentTexture(material.albedoTexture, index: Int(TextureAlbedo.rawValue))
            renderEncoder.setFragmentTexture(material.normalTexture, index: Int(TextureNormal.rawValue))
            renderEncoder.setFragmentTexture(material.roughnessMetalnessOcclusionTexture, index: Int(TextureRoughnessMetalnessOcclusion.rawValue))
            renderEncoder.setFragmentTexture(material.emissionTexture, index: Int(TextureEmissive.rawValue))
        }
        
        if material.doubleSided {
            renderEncoder.setCullMode(.none)
        } else {
            renderEncoder.setCullMode(.back)
        }

        // Update material constants
        var materialData = pipelineState.shaderMaterialData
        renderEncoder.setFragmentBytes(&materialData,
                                       length: MemoryLayout<ShaderMaterialData>.size,
                                       index: Int(BufferIndexMaterials.rawValue))

        // Render primitives
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indexBufferInfo.numIndices,
                                            indexType: indexBufferInfo.indexType,
                                            indexBuffer: buffers[indexBufferInfo.bufferIndex],
                                            indexBufferOffset: indexBufferInfo.offset)
    }
    
}
