//
//  Mesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal
import SparrowAsset

/**
 A mesh.
 
 Contains submeshes and other info needed for rendering.
 */
class Mesh {
    /// Name of the mesh. Usefull for debugging
    let name: String
    
    /// Bounds of the mesh
    let bounds: Bounds
    
    /// List of submeshes
    let submeshes: [Submesh]
    
    /// Vertex and index buffers
    let buffers: [MTLBuffer]
    
    /// Vertex format descriptor
    let vertexDescriptor: MTLVertexDescriptor

    init(name: String, bounds: Bounds, buffers: [MTLBuffer], vertexDescriptor: MTLVertexDescriptor, submeshes: [Submesh]) {
        self.name = name
        self.bounds = bounds
        self.buffers = buffers
        self.vertexDescriptor = vertexDescriptor
        self.submeshes = submeshes
    }
    
    /**
     Add this mesh to the given render set for rendering from given viewPosition.
     
     This creates a render item with all submeshes.
     
     TODO: maybe pass the renderItem to update? so we don't need to allocate
     */
    func addToRenderSet(set: RenderSet, viewPosition: float3, worldTransform: float4x4) {
        // What do we do with renderpass?
        // This function should be called only if the mesh survived culling!
        
        // Calculate approximate depth, used for render sorting
        let (_, _, _, translation) = worldTransform.columns
        let depth: Float = distance(viewPosition, translation.xyz)
        for (index, submesh) in submeshes.enumerated() {
            set.add(submesh.material.renderMode) { item in
                item.depth = depth
                item.mesh = self
                item.submeshIndex = UInt16(index)
                item.worldTransform = worldTransform
            }
        }
    }
}

// MARK: - Rendering

extension Mesh {
    /**
     Render the submesh at given index.
     */
    func render(renderEncoder: MTLRenderCommandEncoder, renderPass: RenderPass, uniforms: Uniforms, submeshIndex: UInt16, worldTransform: float4x4) {
        // TODO: This causes a bridge from ObjC to Swift which causes an allocation of an array
        let submesh = submeshes[Int(submeshIndex)]

        let useDepthOnly = (renderPass == .depthPrePass || renderPass == .shadows) && submesh.depthPipelineState != nil
        if useDepthOnly {
            renderEncoder.setRenderPipelineState(submesh.depthPipelineState!)
        } else {
            renderEncoder.setRenderPipelineState(submesh.pipelineState)
        }
        

        // Set vertex uniforms
        var uniforms = uniforms
        uniforms.modelMatrix = worldTransform
        uniforms.normalMatrix = worldTransform.upperLeft

        renderEncoder.setVertexBytes(&uniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))

        // Set vertex buffers
        for index in 0..<buffers.count {
            renderEncoder.setVertexBuffer(buffers[index], offset: 0, index: index)
        }


        // Set textures
////        if (renderPass == .depthPrePass || renderPass != .shadows) && alphaTest {
////            renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
////        }
//
//        if renderPass != .depthPrePass && renderPass != .shadows {
//            renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
//            renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(TextureNormal.rawValue))
//            renderEncoder.setFragmentTexture(submesh.textures.roughnessMetalnessOcclusion, index: Int(TextureRoughnessMetalnessOcclusion.rawValue))
//            renderEncoder.setFragmentTexture(submesh.textures.emission, index: Int(TextureEmissive.rawValue))
//        }
//        
//
        var materialPtr = submesh.shaderMaterialData
        renderEncoder.setFragmentBytes(&materialPtr,
                                       length: MemoryLayout<ShaderMaterialData>.size,
                                       index: Int(BufferIndexMaterials.rawValue))

        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.indexBufferInfo.numIndices,
                                            indexType: submesh.indexBufferInfo.indexType,
                                            indexBuffer: buffers[submesh.indexBufferInfo.bufferIndex],
                                            indexBufferOffset: submesh.indexBufferInfo.offset)
    }
}
