//
//  MeshLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 19/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal
import SparrowMesh
import SparrowEngine2

/**
 Loader of meshes.
 
 Gives fully built meshes. Might re-use resources when possible.
 */
public class MeshLoader {
    private let device: MTLDevice
    private let textureLoader: TextureLoader
    
    public init(device: MTLDevice, textureLoader: TextureLoader) {
        self.device = device
        self.textureLoader = textureLoader
    }
    
    enum Error: Swift.Error {
        /// Asset could not be found.
        case fileNotFound(URL)
        
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
        let url = AssetLoader.url(forAsset: name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Error.fileNotFound(url)
        }
        
        print("[meshloader] Loading from \(url.path)")
        
        // Load using the SparrowAsset loader which verifies the asset contents.
        let fileRef = try SPMFileLoader.load(from: url)
        
        // Get first mesh or throw -> SAMesh
        guard let saMesh = fileRef.file.mesh else {
            throw Error.unsupportedAsset("Asset contains no mesh.")
        }
        
        let mesh = try createMesh(saFileRef: fileRef,
                                  saAsset: fileRef.file,
                                  saMesh: saMesh)

        return mesh
    }
    
    private func createMesh(saFileRef: SPMFileRef, saAsset: SPMFile, saMesh: SPMMesh) throws -> Mesh {
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
        
        // Create materials
        var materials: [Int:Material] = [:]
        for (materialIndex, saMaterial) in saAsset.materials.enumerated() {
            // Only process materials used in this submesh
            if saMesh.submeshes.first(where: { $0.material == materialIndex }) != nil {
                let mat = try createMaterial(saFileRef: saFileRef,
                                             saAsset: saAsset,
                                             saMaterial: saMaterial)
                materials[materialIndex] = mat
            }
        }
        
        
        // Create submeshes
        let submeshes = try saMesh.submeshes.map {
            try createSubmesh(saAsset: saAsset,
                              saSubmesh: $0,
                              bufferIndexMapping: bufferIndexMapping,
                              vertexDescriptor: vertexDescriptor,
                              materials: materials)
        }
        
        return Mesh(name: saMesh.name,
                    bounds: bounds,
                    buffers: buffers,
                    vertexDescriptor: vertexDescriptor,
                    submeshes: submeshes)
    }
    
    private func createSubmesh(saAsset: SPMFile,
                               saSubmesh: SPMSubmesh,
                               bufferIndexMapping: [Int:Int],
                               vertexDescriptor: MTLVertexDescriptor,
                               materials: [Int:Material]) throws -> Submesh {
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

        guard saSubmesh.material >= 0 && materials[saSubmesh.material] != nil else {
            throw Error.missingMaterial(saSubmesh.material)
        }
        let material = materials[saSubmesh.material]!
        
        return Submesh(name: saSubmesh.name,
                       bounds: bounds,
                       material: material,
                       vertexDescriptor: vertexDescriptor,
                       indexBufferInfo: indexBufferInfo)
    }

    private func createMaterial(saFileRef: SPMFileRef, saAsset: SPMFile, saMaterial: SPMMaterial) throws -> Material {
        func getTexture(_ property: SPMMaterialProperty) -> MTLTexture? {
            switch property {
            case .texture(let textureIndex):
                let saTexture = saAsset.textures[textureIndex]

                do {
//                    if saTexture.relativePath == "ironSphere_phong2SG_albedo.png" {
//                        let url = URL(string: "ironSphere_phong2SG_albedo.astc", relativeTo: saFileRef.url)!
//                        let texture = try textureLoader.load(from: url)
//                        
//                        return texture.mtlTexture
//                    }
                    
                    let url = URL(string: saTexture.relativePath, relativeTo: saFileRef.url)!
                    let texture = try textureLoader.load(from: url)
                    
                    return texture.mtlTexture
                } catch {
                    print("[meshLoader] Could not load texture \(saTexture.relativePath): \(error.localizedDescription)")
                    return nil
                }
            default:
                return nil
            }
        }
        
        func getColor(_ property: SPMMaterialProperty, default defaultColor: float4) -> float4 {
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
                        alpha: albedoColor.w,
        
                        doubleSided: saMaterial.doubleSided)
    }
}

fileprivate extension SPMAlphaMode {
    
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
