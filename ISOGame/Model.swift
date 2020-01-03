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
    
    func render(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms) {
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



class Model2: Node {
//    let meshes: [Mesh2]
    
    let buffers: [STFBuffer]
    let meshNodes: [STFNode]
    let nodes: [STFNode]
    
    init(name: String) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let asset = try? STFAsset(url: assetUrl, device: Renderer.device)
        
        buffers = (asset?.buffers)!
        meshNodes = (asset?.scene(at: 0).meshNodes)!
        nodes = (asset?.scene(at: 0).nodes)!
        
//        buffers = asset.buffers
//        meshNodes = asset?.scene(at: 0).meshNodes
//        nodes = asset.scenes[0].nodes
        
//        let scene = asset?.defaultScene
//        guard let node = scene?.node(at: 0) else { fatalError() }
//
//        let stfMesh = node.mesh
//
////            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
////                                    tangentAttributeNamed: MDLVertexAttributeTangent,
////                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
////            Model.vertexDescriptor = mdlMesh.vertexDescriptor
//
//        let mtkMEsh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
//
//        meshes = zip(mdlMeshes, mtkMeshes).map {
//            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
//        }
        
        super.init()
        self.name = name
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder) {
        for node in meshNodes {
            guard let mesh = node.mesh else { continue }
            
            for submesh in mesh.submeshes {
                renderEncoder.setRenderPipelineState(submesh.pipelineState!)
                var material = submesh.material
                renderEncoder.setFragmentBytes(&material,
                                               length: MemoryLayout<Material>.stride,
                                               index: Int(BufferIndexMaterials.rawValue))
                for attribute in submesh.attributes {
                    renderEncoder.setVertexBuffer(buffers[attribute.bufferIndex].mtlBuffer,
                                                  offset: attribute.offset,
                                                  index: attribute.index)
                }
                var material2 = Material(albedo: float3(1,0,0), specularColor: float3(1,1,1), shininess: 0, metallic: 0, roughness: 0, emission: 0)
                renderEncoder.setFragmentBytes(&material2,
                                               length: MemoryLayout<Material>.stride,
                                               index: Int(BufferIndexMaterials.rawValue))
                
                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: submesh.indexCount,
                                                    indexType: submesh.indexType,
                                                    indexBuffer: submesh.indexBuffer!,
                                                    indexBufferOffset: submesh.indexBufferOffset)
            }
        }
    }
    
}
