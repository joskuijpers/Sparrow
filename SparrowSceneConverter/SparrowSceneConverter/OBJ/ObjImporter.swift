//
//  OBJImporter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowAsset
import simd

class ObjImporter {
    private let url: URL
    private let generateTangents: Bool
    private let positionScale: Float
    
    private var objFile: ObjFile?
    private var mtlFile: MtlFile?
    private var asset: SAAsset!
    
    enum Error: Swift.Error {
        /// The ObjImporter only supports .obj files.
        case fileFormatNotSupported
        /// Material was not found
        case invalidMaterial(String?)
    }
    
    enum Options {
        /// Generate tangents and bitangents
        case generateTangents
        
        /// Scale the vertex positions uniformally
        case uniformScale(Float)
    }
    
    private init(url: URL, options: [Options] = []) throws {
        guard url.pathExtension == "obj" else {
            throw Error.fileFormatNotSupported
        }
        
        self.url = url
        
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
        
        self.generateTangents = generateTangents
        self.positionScale = uniformScale
    }
    
    /**
     Import an asset from given URL.
     */
    static func `import`(from url: URL, options: [Options] = []) throws -> SAAsset {
        let importer = try ObjImporter(url: url, options: options)
        
        return try importer.generate()
    }
}

private extension ObjImporter {
    
    /// Generate the asset
    func generate() throws -> SAAsset {
        let objParser = try ObjParser(url: url, generateTangents: generateTangents)
        objFile = try objParser.parse()
        
        if let mtlPath = objFile?.mtllib,
            let mtlUrl = URL(string: mtlPath, relativeTo: url) {
            let mtlParser = try MtlParser(url: mtlUrl)
            mtlFile = try mtlParser.parse()
        }
        
        try buildAsset()
        asset.updateChecksum()
        
        return asset
    }
    
    /**
     Build asset from values in memory
     
     We first build a vertex list and index list for all submeshes. The submeshes put all indices behind each other,
     creating the index buffer. In front of that we put the final vertex buffer. Each submes has a buffer view pointing somewhere
     in the buffer. We try to optimize the indices by using an index as small as possible. On top of that, we only keep unique vertices.
    */
    func buildAsset() throws {
        let obj = objFile!
        
        asset = SAAsset(generator: "SparrowSceneConverter", origin: url.path)
        
        // Build all submeshes and buffers depending on config
        var meshBounds = SABounds()
        var vertexDataSize: Int = 0
        var submeshes: [SASubmesh]
        var data: Data
        
        if generateTangents {
            (submeshes, data) = try generateSubmeshesAndBuffers(obj: obj, meshBounds: &meshBounds, vertexDataSize: &vertexDataSize, vertexType: TexturedTangentVertex.self)
        } else {
            (submeshes, data) = try generateSubmeshesAndBuffers(obj: obj, meshBounds: &meshBounds, vertexDataSize: &vertexDataSize, vertexType: TexturedVertex.self)
        }
    
        // Add to file
        let buffer = addBuffer(SABuffer(data: data))
        
        var vertexAttributes: [SAVertexAttribute] = [
            .position,
            .normal
        ]
        if generateTangents {
            vertexAttributes.append(.tangent)
            vertexAttributes.append(.bitangent)
        }
        vertexAttributes.append(.uv0)

        
        // Add buffer view for the vertices
        let vertexBufferView = addBufferView(SABufferView(buffer: buffer, offset: 0, length: vertexDataSize))
        
        // Then finally create the mesh
        let mesh = SAMesh(name: url.lastPathComponent,
                          submeshes: submeshes,
                          vertexBuffer: vertexBufferView,
                          vertexAttributes: vertexAttributes,
                          bounds: meshBounds)
        addNodeAndMesh(mesh)
        
        // Update all buffer views with the buffer index, as originally the view pointed to the offset
        // from first index buffer, and did not point to the buffer at all
        for submesh in submeshes {
            let bv = asset.bufferViews[submesh.indices]
            
            let newView = SABufferView(buffer: buffer, offset: bv.offset + vertexDataSize, length: bv.length)
            
            asset.bufferViews[submesh.indices] = newView
        }
    }
    
    /// Generate the list of submeshes with indexed buffers
    private func generateSubmeshesAndBuffers<V>(obj: ObjFile, meshBounds: inout SABounds, vertexDataSize: inout Int, vertexType: V.Type) throws -> ([SASubmesh], Data) where V: ObjTestVertex {
        var vertexBuffer: [V] = []
        var vertexMap: [V:Int] = [:]

        var submeshes: [SASubmesh] = []
        
        var indexBuffer = Data()
        
        // Add indices and vertices for each submesh
        for (_, submesh) in obj.submeshes.enumerated() {
            var submeshBounds = SABounds()
            var submeshIndexBuffer: [UInt32] = []

            for face in submesh.faces {
                for vertexIndex in face.vertIndices {
                    let vertex = submesh.vertices[vertexIndex]
                    
                    // Add full vertex to vertex list
                    let packedVertex = vertexType.init(obj: obj, vertex: vertex, uniformScale: positionScale)
                    
                    // Indexing: only use each vertex once
                    var index: Int = 0
                    if let existingIndex = vertexMap[packedVertex] {
                        index = existingIndex
                    } else {
                        vertexBuffer.append(packedVertex)
                        index = vertexBuffer.count - 1
                        vertexMap[packedVertex] = index
                    }
                    
                    // Add index to index buffer
                    submeshIndexBuffer.append(UInt32(index))
                    
                    // Update bounds of submesh
                    let position = obj.positions[vertex.position - 1] * positionScale
                    submeshBounds = submeshBounds.containing(position)
                }
            }

            // Create material
            let material = try generateMaterial(submesh: submesh)
            
            // Put index buffer with submesh + name + material + bounds.
            let ibSize = MemoryLayout<UInt32>.stride * submeshIndexBuffer.count
            let ibData = Data(bytes: submeshIndexBuffer, count: ibSize)

            // View into the final index buffer
            let bufferView = addBufferView(SABufferView(buffer: -1, offset: indexBuffer.count, length: ibSize))
            
            // Add to final index buffer
            indexBuffer.append(ibData)
            
            let submesh = SASubmesh(name: submesh.name,
                                    indices: bufferView,
                                    material: material,
                                    bounds: submeshBounds,
                                    indexType: .uint32,
                                    primitiveType: .triangle)
            submeshes.append(submesh)
            
            // Update bounds of mesh using bounds of submesh
            meshBounds = meshBounds.containing(submeshBounds)
        }
        
        print("Before indexing: \(obj.submeshes.reduce(0, { $0 + $1.vertices.count })), after: \(vertexBuffer.count)")
        print("Vertex size: \(MemoryLayout<V>.size)")
        
        // Create a final mesh buffer for vertices + index buffers
        vertexDataSize = MemoryLayout<V>.stride * vertexBuffer.count
        
        // Create a data buffer of vertex+index buffer
        var data = Data(bytes: &vertexBuffer, count: vertexDataSize)
        data.append(indexBuffer)

        return (submeshes, data)
    }
    
    /// Generate a material definition from data provided in the mesh and material file.
    private func generateMaterial(submesh: ObjSubmesh) throws -> Int {
        if let materialName = submesh.material, let mat = mtlFile!.materials.first(where: { $0.name == materialName }) {
            var albedo = SAMaterialProperty.none
            if let texture = mat.albedoTexture {
                albedo = SAMaterialProperty.texture(addTexture(texture))
            } else {
                albedo = SAMaterialProperty.color(float4(mat.albedoColor, mat.alpha))
            }
            
            var normals = SAMaterialProperty.none
            if let texture = mat.normalTexture {
                normals = SAMaterialProperty.texture(addTexture(texture))
            }
            
            var emissive = SAMaterialProperty.none
            if let texture = mat.emissiveTexture {
                emissive = SAMaterialProperty.texture(addTexture(texture))
            } else {
                if mat.emissiveColor == float3(0, 0, 0) {
                    // Save None so we spare 3 unused floats
                    emissive = SAMaterialProperty.none
                } else {
                    emissive = SAMaterialProperty.color(float4(mat.emissiveColor, 1))
                }
            }
            
            
            
            print("RO", mat.roughnessTexture)
            print("ME", mat.metallicTexture)
            print("AO", mat.aoTexture)
            
            print("R", mat.roughness)
            print("M", mat.metallic)
            
            // If there are no textures used at all, supply colors. Otherwise, combine existing textures,
            // possibly with colors, into a single texture.
            var rma = SAMaterialProperty.none
            
            if mat.roughnessTexture == nil && mat.metallicTexture == nil && mat.aoTexture == nil {
                print("[obj] RMA: color, no AO")
                rma = SAMaterialProperty.color([mat.roughness, mat.metallic, 1, 0])
            } else {
                let outputUrl = url.appendingToFilename("_\(mat.name)_rmo").deletingPathExtension().appendingPathExtension("png")
                
                print("[obj] Creating new RMA texture at \(outputUrl)...")
                
                try TextureUtil.combine(red: mat.roughnessTexture != nil ? .image(mat.roughnessTexture!) : .color(mat.roughness),
                                        green: mat.metallicTexture != nil ? .image(mat.metallicTexture!) : .color(mat.metallic),
                                        blue: mat.aoTexture != nil ? .image(mat.aoTexture!) : .color(1),
                                        into: outputUrl)
                
                rma = SAMaterialProperty.texture(addTexture(outputUrl))
            }
            
            let m = SAMaterial(name: mat.name,
                               albedo: albedo,
                               normals: normals,
                               roughnessMetalnessOcclusion: rma,
                               emission: emissive,
                               alphaMode: mat.hasAlpha ? .mask : .opaque,
                               alphaCutoff: 0.5)
            return addMaterial(m)
        } else {
            throw Error.invalidMaterial(submesh.material)
        }
    }
}

//MARK: - Adding items to the asset

private extension ObjImporter {
    func addTexture(_ url: URL) -> Int {
        // Create the shortest path possible: relative to the asset
        guard let relativePath = url.relativePath(from: self.url.deletingLastPathComponent()) else {
            fatalError("Could not create relative path for texture")
        }
        
        asset.textures.append(SATexture(relativePath: relativePath))
        return asset.textures.count - 1
    }
    
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
        
        let node = SANode(name: url.deletingPathExtension().lastPathComponent,
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

fileprivate protocol ObjTestVertex: Hashable {
    init(obj: ObjFile, vertex: ObjVertex, uniformScale: Float)
}

/// A vertex with position,normals and texture coordinates
fileprivate struct TexturedVertex: ObjTestVertex {
    init(obj: ObjFile, vertex: ObjVertex, uniformScale: Float = 1) {
        let position = obj.positions[vertex.position - 1] * uniformScale
        let normal = obj.normals[vertex.normal - 1]
        let uv = obj.texCoords[vertex.texCoord - 1]
        
        x = position.x
        y = position.y
        z = position.z
        
        nx = normal.x
        ny = normal.y
        nz = normal.z
        
        u = uv.x
        v = uv.y
    }
    
    let x: Float
    let y: Float
    let z: Float
    
    let nx: Float
    let ny: Float
    let nz: Float
    
    let u: Float
    let v: Float
}

/// A vertex with position,normals, tangents and texture coordinates
fileprivate struct TexturedTangentVertex: ObjTestVertex {
    init(obj: ObjFile, vertex: ObjVertex, uniformScale: Float = 1) {
        let position = obj.positions[vertex.position - 1] * uniformScale
        let normal = obj.normals[vertex.normal - 1]
        let uv = obj.texCoords[vertex.texCoord - 1]
        
        x = position.x
        y = position.y
        z = position.z
        
        nx = normal.x
        ny = normal.y
        nz = normal.z
        
        tx = vertex.tangent.x
        ty = vertex.tangent.y
        tz = vertex.tangent.z
        
        btx = vertex.bitangent.x
        bty = vertex.bitangent.y
        btz = vertex.bitangent.z
        
        u = uv.x
        v = uv.y
    }
    
    let x: Float
    let y: Float
    let z: Float
    
    let nx: Float
    let ny: Float
    let nz: Float
    
    let tx: Float
    let ty: Float
    let tz: Float

    let btx: Float
    let bty: Float
    let btz: Float
    
    let u: Float
    let v: Float
}
