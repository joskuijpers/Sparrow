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
            submesh.render(renderEncoder: renderEncoder)
        }
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
        
        for submesh in submeshes {
            let renderItem = RenderItem(transform: worldTransform, depth: depth, vertexBuffers: mtkMesh.vertexBuffers, submesh: submesh)
            set.add(renderItem)
        }
    }
}
