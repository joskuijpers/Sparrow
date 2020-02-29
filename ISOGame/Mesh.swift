//
//  Mesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Mesh {
    private let mtkMesh: MTKMesh
    private let mdlMesh: MDLMesh
    let submeshes: [Submesh]
    
    let name: String
    let bounds: Bounds
    
    // TODO get rid of this
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor
    
    var vertexBuffers: [MTKMeshBuffer] {
        self.mtkMesh.vertexBuffers
    }
    
    init(name: String) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetUrl,
                             vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                             bufferAllocator: allocator)
        
        self.name = name
        
        let meshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
        if meshes.count != 1 {
            fatalError("Model \(name) contains \(meshes.count) meshes instead of 1")
        }
        
        mdlMesh = meshes.first!
        mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                            tangentAttributeNamed: MDLVertexAttributeTangent,
                                            bitangentAttributeNamed: MDLVertexAttributeBitangent)
        Mesh.vertexDescriptor = mdlMesh.vertexDescriptor
        
        mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        
        submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
            Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
        }
        
        bounds = Bounds(minBounds: mdlMesh.boundingBox.minBounds, maxBounds: mdlMesh.boundingBox.maxBounds)
    }
    
    /**
     Add this mesh to the given render set for rendering from given viewPosition.
     
     This creates a render item with all submeshes.
     
     TODO: maybe pass the renderItem to update? so we don't need to allocate
     */
    func addToRenderSet(set: RenderSet, pass: RenderPass, viewPosition: float3, worldTransform: float4x4) {
        // What do we do with renderpass?
        // This function should be called only if the mesh survived culling!

        // Calculate approximate depth, used for render sorting
        let (_, _, _, translation) = worldTransform.columns
        let depth: Float = distance(viewPosition, translation.xyz)
        
        for (index, _) in submeshes.enumerated() {
            // TODO: depending on submesh render mode, put in opaque or translucent
            
//            set.opaque.add(depth: depth, mesh: self, submeshIndex: uint8(index), worldTransform: worldTransform)
            var item = set.acquire()
            item.set(depth: depth, mesh: self, submeshIndex: uint8(index), worldTransform: worldTransform)
            set.add(item)
        }
    }
}

// MARK: - Rendering

extension Mesh {
    /**
     Render the submesh at given index.
     */
    func render(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms, submeshIndex: uint8, worldTransform: float4x4) {
        let submesh = submeshes[Int(submeshIndex)]

        renderEncoder.setRenderPipelineState(submesh.pipelineState)
        
        // Set vertex uniforms
        var vertexUniforms = vertexUniforms
        vertexUniforms.modelMatrix = worldTransform
        vertexUniforms.normalMatrix = worldTransform.upperLeft
        
        renderEncoder.setVertexBytes(&vertexUniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))
        
        // Set vertex buffers
        for (index, vertexBuffer) in mtkMesh.vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
        }
        
        // Set textures
        renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(TextureNormal.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.roughness, index: Int(TextureRoughness.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.metallic, index: Int(TextureMetallic.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.ambientOcclusion, index: Int(TextureAmbientOcclusion.rawValue))
        //                    renderEncoder.setFragmentTexture(submesh.textures.emissive, index: Int(TextureEmission.rawValue))
        
        var materialPtr = submesh.material
        renderEncoder.setFragmentBytes(&materialPtr,
                                       length: MemoryLayout<Material>.stride,
                                       index: Int(BufferIndexMaterials.rawValue))
        
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.mtkSubmesh.indexCount,
                                            indexType: submesh.mtkSubmesh.indexType,
                                            indexBuffer: submesh.mtkSubmesh.indexBuffer.buffer,
                                            indexBufferOffset: submesh.mtkSubmesh.indexBuffer.offset)
    }
}
