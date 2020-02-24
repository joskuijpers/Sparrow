//
//  Mesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Mesh {
    let mtkMesh: MTKMesh
    let mdlMesh: MDLMesh
    let submeshes: [Submesh]
    
    let name: String
    
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor
    
    
    init(name: String) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetUrl,
                             vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                             bufferAllocator: allocator)
        
//        var mtkMeshes: [MTKMesh] = []
//        let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
//        _ = mdlMeshes.map { mdlMesh in
//            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
//                                    tangentAttributeNamed: MDLVertexAttributeTangent,
//                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
//            Mesh.vertexDescriptor = mdlMesh.vertexDescriptor
//            mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
//        }

//        meshes = zip(mdlMeshes, mtkMeshes).map {
//            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
//        }
        
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
        
//        let bb = mdlMeshes[0].boundingBox
//        boundingBox = Bounds(minBounds: bb.minBounds, maxBounds: bb.maxBounds)
    }
    
    /// Render specified submesh
    func render(renderEncoder: MTLRenderCommandEncoder, submesh: Submesh) {
        renderEncoder.setRenderPipelineState(submesh.pipelineState)
        
        renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(TextureNormal.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.roughness, index: Int(TextureRoughness.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.metallic, index: Int(TextureMetallic.rawValue))
        renderEncoder.setFragmentTexture(submesh.textures.ambientOcclusion, index: Int(TextureAmbientOcclusion.rawValue))
        //                    renderEncoder.setFragmentTexture(submesh.textures.emissive, index: Int(TextureEmission.rawValue))
        
        var material = submesh.material
        renderEncoder.setFragmentBytes(&material,
                                       length: MemoryLayout<Material>.stride,
                                       index: Int(BufferIndexMaterials.rawValue))
        
        let mtkSubmesh = submesh.mtkSubmesh
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: mtkSubmesh.indexCount,
                                            indexType: mtkSubmesh.indexType,
                                            indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                            indexBufferOffset: mtkSubmesh.indexBuffer.offset)
    }
    
    /// Render this mesh
    func render(renderEncoder: MTLRenderCommandEncoder, pass: RenderPass, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms, worldTransform: float4x4) {
        var vUniforms = vertexUniforms
        
        vUniforms.modelMatrix = worldTransform
        vUniforms.normalMatrix = worldTransform.upperLeft
        
        renderEncoder.setVertexBytes(&vUniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))
        
        for (index, vertexBuffer) in mtkMesh.vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
        }
        
        for submesh in submeshes {
            render(renderEncoder: renderEncoder, submesh: submesh)
        }
    }
}
