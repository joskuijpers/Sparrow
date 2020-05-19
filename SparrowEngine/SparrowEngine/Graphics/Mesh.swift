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
    
    private let asset: SAAsset
    private let buffers: [MTLBuffer]
    let vertexDescriptor: MTLVertexDescriptor
    
    enum Error: Swift.Error {
        /// Asset could not be found.
        case notFound
        
        /// Asset contents currently not supported
        case unsupportedAsset(String)
    }
    
    let ibo: Int
    let ibn: Int
    
    init(name: String) throws {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            throw Error.notFound
        }
        let device = Renderer.device!
        
        print("[mesh] Loading from \(assetUrl)")

        let saAsset = try SparrowAssetLoader.load(from: assetUrl)
        asset = saAsset

        // Assume a single mesh
        guard asset.meshes.count == 1 else {
            throw Error.unsupportedAsset("Asset contains more than one mesh")
        }
        
        let saMesh = asset.meshes[0]
        
        self.name = saMesh.name
        
        // Create vertex descriptor
        let vertexDescriptor = VertexDescriptor.build(from: saMesh.vertexAttributes)
        self.vertexDescriptor = vertexDescriptor
        
        // Create MTL buffer(s)
        buffers = asset.buffers.map { (buffer) -> MTLBuffer in
            buffer.data.withUnsafeBytes { (ptr) -> MTLBuffer in
                guard let mtlBuffer = device.makeBuffer(bytes: ptr.baseAddress!, length: buffer.size, options: .storageModeShared) else {
                    fatalError("Unable to allocate MTLBuffer for mesh")
                }
                
                print("Created MTL buffer \(mtlBuffer)")
                
                return mtlBuffer
            }
        }
        
        // Create submeshes
        submeshes = saMesh.submeshes.map({ (saSubmesh) -> Submesh in
            Submesh(saAsset: saAsset, saSubmesh: saSubmesh, vertexDescriptor: vertexDescriptor)
        })
        
        ibo = saAsset.bufferViews[saMesh.submeshes[10].indices].offset
        ibn = saAsset.bufferViews[saMesh.submeshes[10].indices].length / MemoryLayout<UInt32>.size
        
        
        // Store bounds
        bounds = Bounds(from: saMesh.bounds)
        

        print("Loaded mesh \(self.name) with bounds \(bounds)")
    }
    
    /**
     Add this mesh to the given render set for rendering from given viewPosition.
     
     This creates a render item with all submeshes.
     
     TODO: maybe pass the renderItem to update? so we don't need to allocate
     */
    func addToRenderSet(set: RenderSet, viewPosition: float3, worldTransform: float4x4) {
        // What do we do with renderpass?
        // This function should be called only if the mesh survived culling!

//        print("Add mesh to render set (needs culling of submeshes)")
        
        // Calculate approximate depth, used for render sorting
        let (_, _, _, translation) = worldTransform.columns
        let depth: Float = distance(viewPosition, translation.xyz)
//
        for (index, _) in submeshes.enumerated() {
            // TODO: depending on submesh render mode, put in opaque or translucent
            // SO store render mode inside the mesh...
            // TODO: add submesh culling

            if index == 10 {
                set.add(.opaque) { item in
                    item.depth = depth
                    item.mesh = self
                    item.submeshIndex = UInt16(index)
                    item.worldTransform = worldTransform
                }
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

        
        
        
        
//
//        // TODO: apple does:
//            // mesh
//                // vertex buffers
//            // submesg
//                // textures
//                // material uniform
//        // but this does not work well when splitting the submesh rendering

        if renderPass == .depthPrePass || renderPass == .shadows {
            renderEncoder.setRenderPipelineState(submesh.depthPipelineState)
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


        // TODO: MOVE TO SUBMESH
        // Set textures
//        if (renderPass == .depthPrePass || renderPass != .shadows) && alphaTest {
//            renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
//        }

        if renderPass != .depthPrePass && renderPass != .shadows {
            renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
            renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(TextureNormal.rawValue))
            renderEncoder.setFragmentTexture(submesh.textures.roughnessMetalnessOcclusion, index: Int(TextureRoughnessMetalnessOcclusion.rawValue))
            renderEncoder.setFragmentTexture(submesh.textures.emission, index: Int(TextureEmissive.rawValue))
        }
        

        var materialPtr = submesh.material
        renderEncoder.setFragmentBytes(&materialPtr,
                                       length: MemoryLayout<Material>.size,
                                       index: Int(BufferIndexMaterials.rawValue))

        // Move this to submesh. Store this info in submesh when loading (SA buffer index, index type, offset)
        
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: ibn,
                                            indexType: .uint32,
                                            indexBuffer: buffers[0],
                                            indexBufferOffset: ibo)

        // END MOVE TO SUBMESH
    }
}
