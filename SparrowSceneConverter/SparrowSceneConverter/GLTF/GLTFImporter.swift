//
//  GLTFImporter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import GLTF
import SparrowAsset

final class GLTFImporter {
    private let inputUrl: URL
    private let outputUrl: URL
    private let generateTangents: Bool
    //    private let positionScale: Float
    
    private let textureTool: TextureTool
    private let objectName: String
    
    private var asset: SAAsset!
    private var materialCache: [GLTFMaterial:Int] = [:]
    private var textureCache: [GLTFTexture:Int] = [:]
    
    enum Error: Swift.Error {
        /// The ObjImporter only supports .obj files.
        case fileFormatNotSupported
        
        case invalidContent(String)
        case unsupportedPrimitiveType
        case unsupportedIndexType
        case unsupportedTextureFormat
        case noTextureImage
    }
    
    enum Options {
        /// Generate tangents and bitangents
        case generateTangents
        
        /// Scale the vertex positions uniformally
        case uniformScale(Float)
    }
    
    private init(inputUrl: URL, outputUrl: URL, generateTangents: Bool, uniformScale: Float) throws {
        guard inputUrl.pathExtension == "gltf" else {
            throw Error.fileFormatNotSupported
        }
        
        self.inputUrl = inputUrl
        self.outputUrl = outputUrl
        
        self.objectName = inputUrl.deletingPathExtension().lastPathComponent
        
        self.generateTangents = generateTangents
        //        self.positionScale = uniformScale
        
        self.textureTool = TextureToolAsync(verbose: false)
    }
    
    /**
     Import an asset from given URL.
     */
    static func `import`(from url: URL, to outputUrl: URL, options: [Options] = []) throws -> SAFileRef {
        var generateTangents = false
        var uniformScale: Float = 1
        for option in options {
            switch option {
            case .generateTangents:
                generateTangents = true
            case .uniformScale(let scale):
                uniformScale = scale
            }
        }
        
        let importer = try GLTFImporter(inputUrl: url, outputUrl: outputUrl, generateTangents: generateTangents, uniformScale: uniformScale)
        let asset = try importer.generate()
        
        return SAFileRef(url: outputUrl, asset: asset)
    }
}

private extension GLTFImporter {
    
    /// Generate the asset
    private func generate() throws -> SAAsset {
    let allocator = GLTFDefaultBufferAllocator()
        asset = SAAsset(generator: "SparrowSceneConverter", origin: inputUrl.path)
        
        let inAsset = GLTFAsset(url: inputUrl, bufferAllocator: allocator)
        try buildAsset(inAsset)

        asset.updateChecksum()
        
        textureTool.waitUntilFinished()
        
        return asset
    }
    
    private func buildAsset(_ inAsset: GLTFAsset) throws {
        let gltfMesh = try findFirstMesh(inAsset: inAsset)
        
        var meshBounds = SABounds()
        var vertexDataSize = 0
                
        let (submeshes, data) = try generateSubmeshesAndBuffers(gltfMesh: gltfMesh, meshBounds: &meshBounds, vertexDataSize: &vertexDataSize)
        
        // Create vertex attributes
        let vertexAttributes: [SAVertexAttribute] = [
            .position
        ]
        
        // Add the buffer
        asset.buffers.append(SABuffer(data: data))
        let bufferId = asset.buffers.count - 1
        
        // Create buffer view for vertex data
        asset.bufferViews.append(SABufferView(buffer: bufferId,
                                              offset: 0,
                                              length: vertexDataSize))
        let vertexBufferView = asset.bufferViews.count - 1
        
        let mesh = SAMesh(name: gltfMesh.name ?? "mesh",
                          submeshes: submeshes,
                          vertexBuffer: vertexBufferView,
                          vertexAttributes: vertexAttributes,
                          bounds: meshBounds)
        
        asset.meshes.append(mesh)
        asset.nodes.append(SANode(name: "root",
                                  matrix: matrix_identity_float4x4,
                                  children: [],
                                  mesh: asset.meshes.count - 1,
                                  camera: nil,
                                  light: nil))
        asset.scenes.append(SAScene(nodes: [asset.nodes.count - 1]))
    }
    
    /// FInd the mesh to parse in the asset
    private func findFirstMesh(inAsset: GLTFAsset) throws -> GLTFMesh {
        if inAsset.scenes.count != 1 {
            throw Error.invalidContent("Asset contains not exactly 1 scene")
        }
        
        let scene = inAsset.scenes[0]
        if scene.nodes.count != 1 {
            throw Error.invalidContent("Scene contains not exactly 1 node")
        }
        
        let node = scene.nodes[0]
        guard let mesh = node.mesh else {
            throw Error.invalidContent("Node contains no mesh")
        }
        
        return mesh
    }
    
    /// Generate the submeshes and the mesh buffer with vertices and indices
    private func generateSubmeshesAndBuffers(gltfMesh: GLTFMesh, meshBounds: inout SABounds, vertexDataSize: inout Int) throws -> ([SASubmesh], Data) {
        
        // Probably best to just rewrite all the data...
        // For mesh
            // Find attribute set
            // Check it matches across submeshes -> split meshes ?
            // Create vertex buffer
            // Create index buffer
        
            // For each submesh
        for gltfSubmesh in gltfMesh.submeshes {
            var submeshBounds = SABounds()
        
            // Find index buffer data
            // We can directly copy this
        
            // ONCE PER MESH?!
            // Find vertex data using a nice iterator that gives us direct access to each attribute using the Accessors
                // for each vertex, get position for updated bounds
                // build a vertex
                // add vertex to vertex buffer
            
                // do not forget to keep only distinct vertices!
            
            
//            GLTFMTLBuffer *indexBuffer = (GLTFMTLBuffer *)indexAccessor.bufferView.buffer;
//
//            MTLIndexType indexType = (indexAccessor.componentType == GLTFDataTypeUShort) ? MTLIndexTypeUInt16 : MTLIndexTypeUInt32;
//
//            [renderEncoder drawIndexedPrimitives:primitiveType
//                                      indexCount:indexAccessor.count
//                                       indexType:indexType
//                                     indexBuffer:[indexBuffer buffer]
//                               indexBufferOffset:indexAccessor.offset + indexAccessor.bufferView.offset];
            
            // Add bufferview for indices
            // Add index data to index buffer
            
            meshBounds = meshBounds.containing(submeshBounds)
        }
        
            // Update mesh bounds with submesh bounds
            // Add indexbuffer after vertex buffer
            // Set vertexbuffer size
            // return data
        
        
        return ([], Data())
    }

    /// Convert a submesh: grab all properties and build the structure
//    private func convertSubmesh(mesh gltfMesh: GLTFMesh, submesh gltfSubmesh: GLTFSubmesh) throws -> SASubmesh {
//        var materialId = -1
//        if let gltfMaterial = gltfSubmesh.material {
//            if let id = materialCache[gltfMaterial] {
//                materialId = id
//            } else {
//                let material = try convertMaterial(from: gltfMaterial, materialIndex: asset.materials.count + 1)
//                materialId = addMaterial(material)
//                materialCache[gltfMaterial] = materialId
//            }
//        } else {
//            print("CREATE OR GET DEFAULT MATERIAL")
//        }
//
//        guard let primitiveType = gltfSubmesh.primitiveType.toPrimitiveType() else {
//            throw Error.unsupportedPrimitiveType
//        }
//
//        guard let indexType = gltfSubmesh.indexAccessor?.componentType.toIndexType() else {
//            throw Error.unsupportedIndexType
//        }
//
//        // BOUNDS
//
//        // INDEX BUFFER VIEW
//
//        print(gltfSubmesh.vertexDescriptor.attributes)
//        print(gltfSubmesh.vertexDescriptor.bufferLayouts)
//
//        return SASubmesh(name: gltfSubmesh.name ?? "submesh",
//                         indices: 0,
//                         material: materialId,
//                         bounds: SABounds(),
//                         indexType: indexType,
//                         primitiveType: primitiveType)
//    }
    
    /// Turn a GLTF material into an SA material with texture assets
    private func convertMaterial(from gltfMaterial: GLTFMaterial, materialIndex: Int) throws -> SAMaterial {
//        gltfMaterial.isDoubleSided
//        gltfMaterial.isUnlit
        
        let name = gltfMaterial.name ?? "material_\(materialIndex)"
        
        var albedo = SAMaterialProperty.none
        if let texture = gltfMaterial.baseColorTexture {
            let textureId = try generateTexture(texture.texture, supportsAlpha: true, name: "\(objectName)_\(name)_albedo.png")
            albedo = .texture(textureId)
        } else  {
            albedo = .color(gltfMaterial.baseColorFactor)
        }
        
        var normal = SAMaterialProperty.none
        if let texture = gltfMaterial.normalTexture {
            let textureId = try generateTexture(texture.texture, supportsAlpha: false, name: "\(objectName)_\(name)_normal.png")
            normal = .texture(textureId)
        }
        
        var emission = SAMaterialProperty.none
        if let texture = gltfMaterial.emissiveTexture {
            let textureId = try generateTexture(texture.texture, supportsAlpha: false, name: "\(objectName)_\(name)_emission.png")
            emission = .texture(textureId)
        } else  {
            emission = .color(float4(gltfMaterial.emissiveFactor, 0))
        }
        
        var rmo = SAMaterialProperty.none
        if gltfMaterial.metallicRoughnessTexture == nil && gltfMaterial.occlusionTexture == nil {
            rmo = .color([gltfMaterial.roughnessFactor, gltfMaterial.metalnessFactor, 1, 0])
        } else {
            let textureId = try generateCombinedTexture(metallicRoughness: gltfMaterial.metallicRoughnessTexture?.texture,
                                                        occlusion: gltfMaterial.occlusionTexture?.texture,
                                                        name: "\(objectName)_\(name)_rmo.png")
            rmo = .texture(textureId)
        }

        return SAMaterial(name: name,
                          albedo: albedo,
                          normals: normal,
                          roughnessMetalnessOcclusion: rmo,
                          emission: emission,
                          alphaMode: gltfMaterial.alphaMode.toAlphaMode(),
                          alphaCutoff: gltfMaterial.alphaCutoff,
                          doubleSided: gltfMaterial.isDoubleSided)
    }
    
    /// Turn a texture into a format known to SparrowAsset
    private func generateTexture(_ gltfTexture: GLTFTexture, supportsAlpha: Bool, name: String) throws -> Int {
        if let id = textureCache[gltfTexture] {
            return id
        }
        
        guard gltfTexture.type == .uChar else {
            throw Error.unsupportedTextureFormat
        }
        
//        print("TEXT INFO", gltfTexture.format.hasRGB, gltfTexture.format.hasAlpha)
        
        if let bv = gltfTexture.image?.bufferView {
            print("TEXTURE IN BUFFERVIEW \(bv.length)")
        } else if gltfTexture.image?.imageData.count ?? 0 > 0,
            let data = gltfTexture.image?.imageData {
            print("TEXTURE IN DATA \(data)")
        } else if let url = gltfTexture.image?.url {
            print("TEXTURE ON DISK AT \(url) INTO \(name)")
        } else {
            throw Error.noTextureImage
        }

        
        let relativePath = ""
        
        asset.textures.append(SATexture(relativePath: relativePath))
        
        let id = asset.textures.count - 1
        textureCache[gltfTexture] = id
        
        return id
    }
    
    /// Turn a texture into a format known to SparrowAsset while also combining and re-ordering possible channels
    private func generateCombinedTexture(metallicRoughness: GLTFTexture?, occlusion: GLTFTexture?, name: String) throws -> Int {
        print("GENERATE COMBINATION \(metallicRoughness) \(occlusion) INTO \(name)")
        return -1
    }
}

private extension GLTFImporter {
    
    func addMaterial(_ material: SAMaterial) -> Int {
        asset.materials.append(material)
        return asset.materials.count - 1
    }
}

private extension GLTFPrimitiveType {
    func toPrimitiveType() -> SASubmesh.PrimitiveType? {
        switch self {
        case .triangles:
            return .triangle
        default:
            return nil
        }
    }
}

private extension GLTFDataType {
    func toIndexType() -> SASubmesh.IndexType? {
        switch self {
        case .dataTypeUShort:
            return .uint16
        case .dataTypeUInt:
            return .uint32
        default:
            return nil
        }
    }
}

private extension GLTFAlphaMode {
    func toAlphaMode() -> SAAlphaMode {
        switch self {
        case .mask:
            return .mask
        case .blend:
            return .blend
        case .opaque:
            return .opaque
        default:
            return .opaque
        }
    }
}

private extension GLTFTextureFormat {
    var hasAlpha: Bool {
        switch self {
        case .alpha:
            return true
        case .RGBA:
            return true
        default:
            return false
        }
    }
    
    var hasRGB: Bool {
        switch self {
        case .RGB:
            return true
        case .RGBA:
            return true
        default:
            return false
        }
    }
}
