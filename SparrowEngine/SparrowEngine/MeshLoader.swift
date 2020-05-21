//
//  MeshLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 19/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal
import SparrowAsset

/**
 Loader of meshes.
 
 Gives fully built meshes. Might re-use resources when possible.
 */
class MeshLoader {
    private let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    enum Error: Swift.Error {
        /// Asset could not be found.
        case fileNotFound
        
        /// Asset contents currently not supported
        case unsupportedAsset(String)
        
        /// Could not create a gpu buffer.
        case bufferCreationFailed
        
        /// Given index buffer is expected but not found
        case missingIndexBuffer(Int)
        
        /// The material at given index does not exist
        case missingMaterial(Int)
    }
    
    /**
     Load a mesh with given name.
     */
    func load(name: String) throws -> Mesh {
        // Get the asset -> SAAsset
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            throw Error.fileNotFound
        }
        
        print("[meshloader] Loading from \(url)")
        
        // Load using the SparrowAsset loader which verifies the asset contents.
        let asset = try SparrowAssetLoader.load(from: url)
        
        // Get first mesh or throw -> SAMesh
        guard asset.meshes.count == 1 else {
            throw Error.unsupportedAsset("Asset contains not exactly one mesh. Only single-mesh assets are supported.")
        }
        let saMesh = asset.meshes[0]

        let mesh = try createMesh(saAsset: asset, saMesh: saMesh)

        return mesh
    }
    
    private func createMesh(saAsset: SAAsset, saMesh: SAMesh) throws -> Mesh {
        // Not all buffers might be used by this mesh for this asset
        let usedBufferIndices = saMesh.submeshes
            .map { $0.indices }.appending(saMesh.vertexBuffer)
            .map { saAsset.bufferViews[$0].buffer }
            .unique
        
        // Mapping from Asset buffer index to MTL buffer index
        var bufferIndexMapping: [Int:Int] = [:]
        
        // Build GPU buffers
        var buffers: [MTLBuffer] = []
        for assetBufferIndex in usedBufferIndices {
            try saAsset.buffers[assetBufferIndex].data.withUnsafeBytes {
                guard let mtlBuffer = device.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared) else {
                    throw Error.bufferCreationFailed
                }
                
                buffers.append(mtlBuffer)
                bufferIndexMapping[assetBufferIndex] = buffers.count - 1
            }
        }

        // Create vertex descriptor -> MTLVertexDescriptor
        let vertexDescriptor = VertexDescriptor.build(from: saMesh.vertexAttributes)
        
        // Create bounds -> Bounds
        let bounds = Bounds(from: saMesh.bounds)
        
        // Create submeshes
        let submeshes = try saMesh.submeshes.map {
            try createSubmesh(saAsset: saAsset,
                              saSubmesh: $0,
                              bufferIndexMapping: bufferIndexMapping,
                              vertexDescriptor: vertexDescriptor)
        }
        
        return Mesh(name: saMesh.name,
                    bounds: bounds,
                    buffers: buffers,
                    vertexDescriptor: vertexDescriptor,
                    submeshes: submeshes)
    }
    
    private func createSubmesh(saAsset: SAAsset,
                               saSubmesh: SASubmesh,
                               bufferIndexMapping: [Int:Int],
                               vertexDescriptor: MTLVertexDescriptor) throws -> Submesh {
        let bounds = Bounds(from: saSubmesh.bounds)
    
        // Acquire the data needed for the index buffer
        let bufferView = saAsset.bufferViews[saSubmesh.indices]
        guard let mtlBufferIndex = bufferIndexMapping[bufferView.buffer] else {
            throw Error.missingIndexBuffer(bufferView.buffer)
        }
        
        let indexBufferInfo = Submesh.IndexBufferInfo(bufferIndex: mtlBufferIndex,
                                                      offset: bufferView.offset,
                                                      numIndices: bufferView.length / saSubmesh.indexType.size(),
                                                      indexType: saSubmesh.indexType.mtlType())

        guard saSubmesh.material >= 0 && saSubmesh.material < saAsset.materials.count else {
            throw Error.missingMaterial(saSubmesh.material)
        }
        
        let material = try createMaterial(saAsset: saAsset,
                                          saMaterial: saAsset.materials[saSubmesh.material])
        
        return Submesh(name: saSubmesh.name,
                       bounds: bounds,
                       material: material,
                       vertexDescriptor: vertexDescriptor,
                       indexBufferInfo: indexBufferInfo)
    }

    private func createMaterial(saAsset: SAAsset, saMaterial: SAMaterial) throws -> Material {

        // Colors
        
        // Textures (loaded into MTLTexture optional)
        
        // Shader name -> String (Enum with rawValue string)

        // Alpha mode
        var renderMode: RenderMode = .opaque
        switch saMaterial.alphaMode {
        case .mask:
            renderMode = .cutOut
        case .blend:
            renderMode = .translucent
        default:
            renderMode = .opaque
        }
        
        return Material(name: saMaterial.name,
                        renderMode: renderMode)
    }
    
    // TODO: this has to be used when the submesh material changes too....
    // So maybe put this in Submesh and call them from material{didSet{ constants = {}, build/build }}
//    private func createFunctionConstants(material: Material) -> MTLFunctionConstantValues {}
//    private func buildDepthPipelineState() {}
//    private func buildPipelineState() {}
}

/*
 
 Render code stays in the mesh/submesh class:
 
 - Mesh has addToQueue with frustum. Tests whether bounds are in frustum
    then forwards to submesh
 - Submesh tests for frustum too (forward the mesh)
    then adds to queue
    uses bounds for depth to camera (find closest point in bounds to camera) / use center until better solution
    uses alphaMode to decide on queue
 
 - Mesh :render(submeshIndex, worldTransform, uniforms, renderEncoder, renderPass)
    - Set vertex buffers
    - Update and set uniform buffer
    
    - Submesh:render(renderEncoder, renderPass)
        - Set textures
        - Set pipeline state
        - Draw triangles
 
 */





//private extension Submesh.Textures {
//
//    /// Initialize a texture set using an MDLMaterial
//    init(saMaterial: SAMaterial, saAsset: SAAsset) {
//        func property(_ property: SAMaterialProperty) -> MTLTexture? {
//            switch property {
//            case .texture(let textureId):
//                let path = saAsset.textures[textureId].relativePath
//
//                // TODO: need to use path relative to the asset
////                print("[mesh] Acquiring texture \(path)")
//                guard let texture = Renderer.textureLoader.load(imageName: path) else {
//                    fatalError("Unable to load texture \(path)")
//                }
//
//                return texture.mtlTexture
//            default:
//                return nil
//            }
//        }
//
//        albedo = property(saMaterial.albedo)
//        normal = property(saMaterial.normals)
//        roughnessMetalnessOcclusion = property(saMaterial.roughnessMetalnessOcclusion)
//        emission = property(saMaterial.emissive)
//    }
//}
//
//private extension Material {
//
//    /// Initialiaze a Material structure using an MDLMaterial
//    init(saMaterial: SAMaterial, saAsset: SAAsset) {
//        self.init()
//
//        func property(_ property: SAMaterialProperty) -> float4? {
//            switch property {
//            case .color(let color):
//                return color;
//            default:
//                return nil
//            }
//        }
//
//        if let color = property(saMaterial.albedo) {
//            albedo = color.xyz // TODO add alpha
//        }
//
//        if let rma = property(saMaterial.roughnessMetalnessOcclusion) {
//            metallic = rma.x
//            roughness = rma.y
//        }
//
//        if let color = property(saMaterial.emissive) {
//            emission = color.xyz
//        }
//    }
//}
