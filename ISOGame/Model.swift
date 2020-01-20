//
//  Model.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit
import STF

class Model: Node {
    let meshes: [Mesh]
    
    
    // material parameters
//    renderingMode: opaque, transparent/transluecent (alpha blending), cutout (- alpha cutoff), using functionConstants
    // albedo color OR albedo map
    // normal map optiona;
    // occlusion optional (default: 1)
    // metallic optional (default: slider input)
    // roughness optional (default: slider input)
    // availability of the texture does not mean availability of value: might have metallic texture but constant roughness
    // so we need to keep track of that in the function constants, even thouygh we pack them:
    // R = metallic, G = roughness, B = ? heightmap ?, A = occlusion
    
    
    
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor
    
    init(name: String) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetUrl,
                             vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                             bufferAllocator: allocator)
        
        var mtkMeshes: [MTKMesh] = []
        let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
        _ = mdlMeshes.map { mdlMesh in
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
            Model.vertexDescriptor = mdlMesh.vertexDescriptor
            mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
        }

        meshes = zip(mdlMeshes, mtkMeshes).map {
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
        }
        
        super.init()
        self.name = name
        
        let bb = mdlMeshes[0].boundingBox
        boundingBox = AxisAlignedBoundingBox(minBounds: bb.minBounds, maxBounds: bb.maxBounds)
    }
}

// MARK: - Rendering

extension Model: Renderable {
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
    
    func render(renderEncoder: MTLRenderCommandEncoder, pass: RenderPass, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms) {
        var vUniforms = vertexUniforms
        
        vUniforms.modelMatrix = worldTransform
        vUniforms.normalMatrix = worldTransform.upperLeft
        
        renderEncoder.setVertexBytes(&vUniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))
        
        for mesh in self.meshes {
            for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated() {
                renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
            }
            
            for submesh in mesh.submeshes {
                render(renderEncoder: renderEncoder, submesh: submesh)
            }
        }
    }
}
