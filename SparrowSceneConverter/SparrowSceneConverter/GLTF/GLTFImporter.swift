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
        case noIndexAccessor
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
                
        let (submeshes, data) = try generateSubmeshesAndBuffers(gltfMesh: gltfMesh, meshBounds: &meshBounds, vertexDataSize: &vertexDataSize, vertexType: TexturedTangentVertex.self)
        
        // Create vertex attributes
        let vertexAttributes: [SAVertexAttribute] = [
            .position
        ]
        
        // Add the buffer
        let buffer = addBuffer(SABuffer(data: data))
        
        // Create buffer view for vertex data
        let vertexBufferView = addBufferView(SABufferView(buffer: buffer,
                                                          offset: 0,
                                                          length: vertexDataSize))
        
        addNodeAndMesh(SAMesh(name: gltfMesh.name ?? "mesh",
                              submeshes: submeshes,
                              vertexBuffer: vertexBufferView,
                              vertexAttributes: vertexAttributes,
                              bounds: meshBounds))
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
    private func generateSubmeshesAndBuffers<V>(gltfMesh: GLTFMesh, meshBounds: inout SABounds, vertexDataSize: inout Int, vertexType: V.Type) throws -> ([SASubmesh], Data) where V: GLTFTransferVertex {
        var submeshes: [SASubmesh] = []
        var indexBuffers = Data()
        
        // TODO: MOVE VERTEX FORMAT OUTSIDE OBJ SO WE CAN RE-USE
        
        
        // Find vertex data using a nice iterator that gives us direct access to each attribute using the Accessors
            // for each vertex, get position for updated bounds
            // build a vertex
            // add vertex to vertex buffer
            // keep all indices intact!

        
        
        // Acquire material and index buffer
        for gltfSubmesh in gltfMesh.submeshes {
            // Find index buffer data
            guard let indexAccessor = gltfSubmesh.indexAccessor, let gltfIndexBufferView = indexAccessor.bufferView else {
                throw Error.noIndexAccessor
            }
            
            
            print("VD", gltfSubmesh.vertexDescriptor)
            
            // Grab the portion of the data
            let buffer = gltfIndexBufferView.buffer!
            let indexOffset = gltfIndexBufferView.offset + indexAccessor.offset
            let ibSize = indexAccessor.count * indexAccessor.componentType.size
            let bufferData = Data(bytes: buffer.contents.advanced(by: indexOffset), count: ibSize)

            print("INDICES DATA \(bufferData)")
            
            // Acquire bounds of the submesh
            let range = gltfSubmesh.accessorsForAttributes[GLTFAttributeSemanticPosition]!.valueRange
            let minBound = float3(range.minValue.0, range.minValue.1, range.minValue.2)
            let maxBound = float3(range.maxValue.0, range.maxValue.1, range.maxValue.2)
            let submeshBounds = SABounds(min: minBound, max: maxBound)

            // Get material
            let material = try generateMaterial(from: gltfSubmesh.material, withIndex: asset.materials.count + 1)
            
            // Add bufferview for indices. TODO: need to reference the buffer somehow
            let indexBufferView = addBufferView(SABufferView(buffer: -1, offset: indexBuffers.count, length: ibSize))
            
            // Add index data to index buffer
            indexBuffers.append(bufferData)
            
            // Create submesh
            let saSubmesh = SASubmesh(name: gltfSubmesh.name ?? "submesh",
                                      indices: indexBufferView,
                                      material: material,
                                      bounds: submeshBounds,
                                      indexType: indexAccessor.componentType.toIndexType()!,
                                      primitiveType: .triangle)
            submeshes.append(saSubmesh)
            
            meshBounds = meshBounds.containing(submeshBounds)
        }
        
        // Add indexbuffer after vertex buffer
        // Set vertexbuffer size
        
        print("MESH \(meshBounds)")
        
        
        return (submeshes, Data())
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
    
    /// Generate a material from given info. Might return a default material.
    private func generateMaterial(from gtlfMaterial: GLTFMaterial?, withIndex index: Int) throws -> Int {
        var materialId = -1
        if let mat = gtlfMaterial {
            if let id = materialCache[mat] {
                materialId = id
            } else {
                let material = try convertMaterial(from: mat, materialIndex: index)
                materialId = addMaterial(material)
                materialCache[mat] = materialId
            }
        } else {
            print("CREATE OR GET DEFAULT MATERIAL")
            
            let material = createDefaultMaterial()
            materialId = addMaterial(material)
        }
        
        return materialId
    }
    
    private func createDefaultMaterial() -> SAMaterial {
        return SAMaterial(name: "default",
                          albedo: .color([1, 1, 1, 1]),
                          normals: .none,
                          roughnessMetalnessOcclusion: .color([1, 1, 0, 0]),
                          emission: .none,
                          alphaMode: .opaque,
                          alphaCutoff: 0.5,
                          doubleSided: false)
    }
    
    /// Turn a GLTF material into an SA material with texture assets
    private func convertMaterial(from gltfMaterial: GLTFMaterial, materialIndex: Int) throws -> SAMaterial {
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
        
        // Create output URL
        let targetUrl = outputUrl.deletingLastPathComponent().appendingPathComponent(name)
        
        if let bv = gltfTexture.image?.bufferView {
//            print("TEXTURE IN BUFFERVIEW \(bv.length)")
            
            // Extract data from BV
            // Using mime type, determine extension
            // Write to /tmp
            // Do convert
        } else if gltfTexture.image?.imageData.count ?? 0 > 0,
            let data = gltfTexture.image?.imageData {
//            print("TEXTURE IN DATA \(data)")
            
            // Write to /tmp
            // Do convert
        } else if let url = gltfTexture.image?.url {
//            print("TEXTURE ON DISK AT \(url) INTO \(targetUrl)")
            
            // Do convert
        } else {
            throw Error.noTextureImage
        }

        // Create relative path for outputURL and asset output url
        guard let relativePath = targetUrl.relativePath(from: outputUrl) else {
            fatalError("[tex] Could not create relative path for texture")
        }
        
//        print("CREATED IMAGE \(relativePath)")
        
        asset.textures.append(SATexture(relativePath: relativePath))
        
        let id = asset.textures.count - 1
        textureCache[gltfTexture] = id
        
        return id
    }
    
    /// Turn a texture into a format known to SparrowAsset while also combining and re-ordering possible channels
    private func generateCombinedTexture(metallicRoughness: GLTFTexture?, occlusion: GLTFTexture?, name: String) throws -> Int {
//        print("GENERATE COMBINATION \(metallicRoughness) \(occlusion) INTO \(name)")
        return -1
    }
}

private extension GLTFImporter {

    // THIS CODE REPEATS EVERY IMPORTER.... PROTOCOL?
    
    func addMaterial(_ material: SAMaterial) -> Int {
        asset.materials.append(material)
        return asset.materials.count - 1
    }
    
    func addBufferView(_ bufferView: SABufferView) -> Int {
        asset.bufferViews.append(bufferView)
        return asset.bufferViews.count - 1
    }
    
    func addBuffer(_ buffer: SABuffer) -> Int {
        asset.buffers.append(buffer)
        return asset.buffers.count - 1
    }
    
    func addNodeAndMesh(_ mesh: SAMesh) {
        asset.meshes.append(mesh)
        let meshIndex = asset.meshes.count - 1
        
        let node = SANode(name: objectName,
                          matrix: matrix_identity_float4x4,
                          children: [],
                          mesh: meshIndex,
                          camera: nil,
                          light: nil)
        asset.nodes.append(node)
        
        let scene = SAScene(nodes: [asset.nodes.count - 1])
        asset.scenes.append(scene)
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
    
    var size: Int {
        switch self {
        case .dataTypeUShort:
            return 2
        case .dataTypeUInt:
            return 4
        default:
            fatalError("Unsupported size")
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

fileprivate protocol GLTFTransferVertex {
}

extension TexturedVertex: GLTFTransferVertex {
//    init(obj: ObjFile, vertex: ObjVertex, uniformScale: Float = 1) {
//        let position = obj.positions[vertex.position - 1] * uniformScale
//        let normal = obj.normals[vertex.normal - 1]
//        let uv = obj.texCoords[vertex.texCoord - 1]
//
//        x = position.x
//        y = position.y
//        z = position.z
//
//        nx = normal.x
//        ny = normal.y
//        nz = normal.z
//
//        u = uv.x
//        v = uv.y
//    }
}

extension TexturedTangentVertex: GLTFTransferVertex {
//    init(obj: ObjFile, vertex: ObjVertex, uniformScale: Float = 1) {
//        let position = obj.positions[vertex.position - 1] * uniformScale
//        let normal = obj.normals[vertex.normal - 1]
//        let uv = obj.texCoords[vertex.texCoord - 1]
//        
//        x = position.x
//        y = position.y
//        z = position.z
//        
//        nx = normal.x
//        ny = normal.y
//        nz = normal.z
//        
//        tx = vertex.tangent.x
//        ty = vertex.tangent.y
//        tz = vertex.tangent.z
//        
//        btx = vertex.bitangent.x
//        bty = vertex.bitangent.y
//        btz = vertex.bitangent.z
//        
//        u = uv.x
//        v = uv.y
//    }
}
