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
        func getTexture(_ property: SAMaterialProperty) -> MTLTexture? {
            switch property {
            case .texture(let textureIndex):
                let saTexture = saAsset.textures[textureIndex]

                guard let texture = Renderer.textureLoader.load(imageName: saTexture.relativePath) else {
                    print("[meshLoader] Could not find texture \(saTexture.relativePath)")
                    return nil
                }
                
                return texture.mtlTexture
            default:
                return nil
            }
        }
        
        func getColor(_ property: SAMaterialProperty, default defaultColor: float4) -> float4 {
            switch property {
            case .color(let color):
                return color
            default:
                return defaultColor
            }
        }
        
        // Load properties
        let albedoTexture = getTexture(saMaterial.albedo)
        let albedoColor = getColor(saMaterial.albedo, default: [0, 0, 0, 1])
        
        let normalTexture = getTexture(saMaterial.normals)
        
        let rmoTexture = getTexture(saMaterial.roughnessMetalnessOcclusion)
        let rmoValues = getColor(saMaterial.roughnessMetalnessOcclusion, default: [1, 0, 0, 0])
        
        let emissionTexture = getTexture(saMaterial.emission)
        
        // Shader name -> String (Enum with rawValue string)
        // TODO
        
        return Material(name: saMaterial.name,
                        renderMode: saMaterial.alphaMode.renderMode(),

                        albedoTexture: albedoTexture,
                        normalTexture: normalTexture,
                        roughnessMetalnessOcclusionTexture: rmoTexture,
                        emissionTexture: emissionTexture,

                        albedo: albedoColor.xyz,
                        roughness: rmoValues.x,
                        metalness: rmoValues.y,
                        emission: float3.zero,

                        alphaCutoff: saMaterial.alphaCutoff,
                        alpha: albedoColor.w)
    }
}

fileprivate extension SAAlphaMode {
    
    /// Render mode for this alpha mode.
    func renderMode() -> RenderMode {
        switch self {
        case .mask:
            return .cutOut
        case .blend:
            return .translucent
        default:
            return .opaque
        }
    }
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