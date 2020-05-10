//
//  OBJImporter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

class ObjImporter {
    private let url: URL
    
    private var objFile: ObjFile?
    private var mtlFile: MtlFile?
    private var asset: SAAsset!
    
    enum Error: Swift.Error {
        /// The ObjImporter only supports .obj files.
        case fileFormatNotSupported
    }
    
    private init(url: URL) throws {
        guard url.pathExtension == "obj" else {
            throw Error.fileFormatNotSupported
        }
        
        self.url = url
    }
    
    /**
     Import an asset from given URL.
     */
    static func `import`(from url: URL) throws -> SAAsset {
        let importer = try ObjImporter(url: url)
        
        return try importer.generate()
    }
}

private extension ObjImporter {
    
    /// Generate the asset
    func generate() throws -> SAAsset {
        let objParser = try ObjParser(url: url)
        objFile = try objParser.parse()
        
        if let mtlPath = objFile?.mtllib,
            let mtlUrl = URL(string: mtlPath, relativeTo: url) {
            let mtlParser = try MtlParser(url: mtlUrl)
            mtlFile = try mtlParser.parse()
        }
        
        buildAsset()
        asset.updateChecksum()
        
        return asset
    }
    
    /**
     Build asset from values in memory
     
     We first build a vertex list and index list for all submeshes. The submeshes put all indices behind each other,
     creating the index buffer. In front of that we put the final vertex buffer. Each submes has a buffer view pointing somewhere
     in the buffer. We try to optimize the indices by using an index as small as possible. On top of that, we only keep unique vertices.
    */
    func buildAsset() {
        let obj = objFile!
        let mtl = mtlFile!
        
        let header = SAFileHeader(version: .version1, generator: "SparrowSceneConverter", origin: url.path)
        asset = SAAsset(header: header)
        
        // Vertex format. SIMD can't be used here due to the massive padding to keep alignment.
        struct Vertex: Hashable, Equatable {
            let x: Float
            let y: Float
            let z: Float
            let nx: Float
            let ny: Float
            let nz: Float
            
//            let tx: Float = 0
//            let ty: Float = 0
//            let tz: Float = 0
//            
//            let btx: Float = 0
//            let bty: Float = 0
//            let btz: Float = 0
            
            let u: Float
            let v: Float
        }

        var meshMin = float3(Float.infinity, Float.infinity, Float.infinity)
        var meshMax = float3(-Float.infinity, -Float.infinity, -Float.infinity)
        
        var vertexBuffer: [Vertex] = []
        var vertexMap: [Vertex:Int] = [:]
        var indexBuffer = Data()
        var submeshes: [SASubmesh] = []
        
        // Find total number of possible vertices
        let totalMaxVertices = obj.submeshes.map { $0.faces.count * 3 }.reduce(0) {$0 + $1 }
        let use16Bit = totalMaxVertices < UInt16.max
        
        // Add indices and vertices for each submesh
        for (_, submesh) in obj.submeshes.enumerated() {
            var submeshMin = float3(Float.infinity, Float.infinity, Float.infinity)
            var submeshMax = float3(-Float.infinity, -Float.infinity, -Float.infinity)
            
            var submeshIndexBuffer16: [UInt16] = []
            var submeshIndexBuffer32: [UInt32] = []

            for face in submesh.faces {
                for vertex in face.vertices {
                    // Add full vertex to vertex list
                    let position = obj.positions[vertex.position - 1]
                    let normal = obj.normals[vertex.normal - 1]
                    let uv = obj.texCoords[vertex.texCoord - 1]
                    let fVertex = Vertex(x: position.x, y: position.y, z: position.z, nx: normal.x, ny: normal.y, nz: normal.z, u: uv.x, v: uv.y)
                    
                    var index: Int = 0
                    if let existingIndex = vertexMap[fVertex] {
                        index = existingIndex
                    } else {
                        // Does not exist yet, add
                        vertexBuffer.append(fVertex)
                        index = vertexBuffer.count - 1
                        vertexMap[fVertex] = index
                    }
                    
                    // Add index to index buffer
                    if use16Bit {
                        submeshIndexBuffer16.append(UInt16(index))
                    } else {
                        submeshIndexBuffer32.append(UInt32(index))
                    }
                    
                    // Update bounds of submesh
                    submeshMin = min(submeshMin, position)
                    submeshMax = max(submeshMax, position)
                }
            }
        
            // Create material
            var material: Int?
            if let materialName = submesh.material, let mat = mtl.materials.first(where: { $0.name == materialName }) {
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
                
                var rma = SAMaterialProperty.none
                
                let m = SAMaterial(name: mat.name,
                                   albedo: albedo,
                                   normals: normals,
                                   roughnessMetalnessOcclusion: rma,
                                   emissive: emissive,
                                   alphaMode: .opaque,
                                   alphaCutoff: 0.5)
                material = addMaterial(m)
            } else {
                material = -1
            }
            
            // Put index buffer with submesh + name + material + bounds.
            let ibSize = use16Bit ? MemoryLayout<UInt16>.stride * submeshIndexBuffer16.count : MemoryLayout<UInt32>.stride * submeshIndexBuffer32.count
            let ibData = use16Bit ? Data(bytes: submeshIndexBuffer16, count: ibSize) : Data(bytes: submeshIndexBuffer32, count: ibSize)

            // View into the final buffer
            let bufferView = addBufferView(SABufferView(buffer: -1, offset: indexBuffer.count, length: ibSize))
            
            // Add to final buffer
            indexBuffer.append(ibData)
            
            let submesh = SASubmesh(indices: bufferView, material: material!, min: submeshMin, max: submeshMax, indexType: use16Bit ? .uint16 : .uint32)
            submeshes.append(submesh)
            
            // Update bounds of mesh using bounds of submesh
            meshMin = min(meshMin, submeshMin)
            meshMax = max(meshMax, submeshMax)
        }
        
        // Create a final mesh buffer for vertices + index buffers
        let vertexDataSize = MemoryLayout<Vertex>.stride * vertexBuffer.count
        var data = Data(bytes: &vertexBuffer, count: vertexDataSize)
        data.append(indexBuffer)

        // Add to file
        let buffer = addBuffer(SABuffer(size: data.count, data: data))
        
        let vertexAttributes: [SAVertexAttribute] = [
            .position,
            .normal,
//            .tangent,
//            .bitangent,
            .uv0
        ]
        
        // Add buffer view for the vertices
        let vertexBufferView = addBufferView(SABufferView(buffer: buffer, offset: 0, length: vertexDataSize))
        
        // Then finally create the mesh
        let mesh = SAMesh(name: url.lastPathComponent,
                          submeshes: submeshes,
                          vertexBuffer: vertexBufferView,
                          vertexAttributes: vertexAttributes,
                          min: meshMin,
                          max: meshMax)
        addNodeAndMesh(mesh)
        
        // Update all buffer views with the buffer index, as originally the view pointed to the offset
        // from first index buffer, and did not point to the buffer at all
        for submesh in submeshes {
            var bv = asset.bufferViews[submesh.indices]
            bv.buffer = buffer
            bv.offset += vertexDataSize
            asset.bufferViews[submesh.indices] = bv
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

