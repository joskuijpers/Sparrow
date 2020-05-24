//
//  ObjParser.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

class ObjParser: StructuredTextParser {
    let url: URL
    let shouldGenerateTangents: Bool
    
    var obj = ObjFile()
    var currentMaterial: String?
    var currentGroup: String?
    var currentObject: String?
    
    var vertices: [ObjVertex] = []
    var positions: [float3] = []
    var normals: [float3] = []
    var texCoords: [float2] = []
    var faces: [ObjFace] = []
    
    enum Error: Swift.Error {
        case invalidFace(Substring, SourceLocation)
        
        /// The face is not supported
        case unsupportedFace(Int)
        
        /// The faces are not triangle and are unsupported for tangent generation
        case noTangentsForNonTriangle
        
        /// There are no normals or UVs, required for tangent generation
        case noNormalsOrUvs
    }
    
    init(url: URL, generateTangents: Bool) throws {
        self.url = url
        self.shouldGenerateTangents = generateTangents
        
        let input = try String(contentsOf: url)
        super.init(input: input)
    }
    
    func parse() throws -> ObjFile {
        while index < input.endIndex {
            try line()
        }
        
        if currentGroup != nil {
            try finishSubmesh()
        }
        
        obj.positions = positions
        obj.normals = normals
        obj.texCoords = texCoords
        
        return obj
    }
    
    /// Read a line
    func line() throws {
        // Skip comments
        while match("#") {
            skipLine()
        }

        // Whitespace can precede an identifier
        skipWhitespaceAndNewlines()
        
        let action = identifier()
        
        switch action {
        case "mtllib":
            obj.mtllib = String(text())
            
        case "g":
            let name = String(text())
            if currentGroup != nil {
                try finishSubmesh()
            }
            startSubmesh(name: name)
            
        case "o": // Has no effect
            currentObject = String(text())
        case "usemtl":
            currentMaterial = String(text())
            
        case "v":
            positions.append(parseFloat3())
        case "vn":
            normals.append(parseFloat3())
        case "vt":
            texCoords.append(parseFloat2())
        case "f":
            faces.append(try face())
            
        case "s": // Not used in Sparrow
            skipLine()
            
        case .none:
            print("[obj] Could not read action at \(offsetToLocation(offset))")
        default:
            print("[obj] Unhandled action: \(action!) at \(offsetToLocation(offset))")
            skipLine()
        }
        
        // Skip newline at the end
        skipNewlines()
    }
    
    func startSubmesh(name: String) {
        currentGroup = name
        faces = []
        vertices = []
    }
    
    func finishSubmesh() throws {
        if faces.count == 0 {
            // Some obj files put all vertex data in a group, and then build faces per actual group
            print("[obj] Found group with no faces. Skipping.")
            return
        }
        
        let name = (currentObject ?? "") + (currentGroup ?? "default")
        
        // Triangulate all meshes
        faces = try triangulate(faces: faces)
        
        // Save time by not always generating
        if shouldGenerateTangents {
            try generateTangents()
        }
        
        print("[obj] Building submesh with name \(name), faces \(faces.count), material \(currentMaterial ?? "default")")
        obj.submeshes.append(ObjSubmesh(name: name, material: currentMaterial, faces: faces, vertices: vertices))
    }
    
    /// Parse a vertex of a face
    func vertex(input: Substring) throws -> ObjVertex {
        let items = input.split(separator: "/")
        
        if items.count != 3 {
            // todo: support tex = 0, normal = 0
            throw Error.invalidFace(input, offsetToLocation(offset))
        }
        
        let vert = Int(items[0])!
        let tex = items.count >= 2 ? Int(items[1])! : 0
        let norm = items.count >= 3 ? Int(items[2])! : 0
        
        return ObjVertex(position: vert, normal: norm, texCoord: tex)
    }
    
    /// Parse a face. Might give 2 faces when turning a quad into a triangle
    func face() throws -> ObjFace {
        let verts = try restOfLine()
            .split(separator: " ")
            .map({ (str) -> Int in
                let vert = try vertex(input: str)
                vertices.append(vert)
                return vertices.count - 1
            })
            
        return ObjFace(vertIndices: verts)
    }
}

// MARK: - Post processing actions

extension ObjParser {
    // https://github.com/assimp/assimp/blob/master/code/PostProcessing/TriangulateProcess.cpp#L227
    /// Triangulate the faces. Supports triangles (no conversion) and quads (fast conversion)
    private func triangulate(faces: [ObjFace]) throws -> [ObjFace] {
        // Do not run if there are no non-triangles
        let needed = faces.filter { $0.vertIndices.count != 3 }.count > 0
        if !needed {
            return faces
        }
        
        var result: [ObjFace] = []

        for face in faces {
            let numIndices = face.vertIndices.count
            if numIndices == 3 {
                result.append(face)
            } else if numIndices == 4 {
                var startIndex = 0

                for i in 0..<4 {
                    let v0 = positions[vertices[face.vertIndices[(i + 3) % 4]].position - 1] // obj is 1-indexed
                    let v1 = positions[vertices[face.vertIndices[(i + 2) % 4]].position - 1]
                    let v2 = positions[vertices[face.vertIndices[(i + 1) % 4]].position - 1]

                    let v = positions[vertices[face.vertIndices[i]].position - 1]

                    let left = normalize(v0 - v)
                    let diag = normalize(v1 - v)
                    let right = normalize(v2 - v)

                    let angle = acos(dot(left, diag)) + acos(dot(right, diag))
                    if angle > π {
                        startIndex = i
                        break
                    }
                }

                let temp = [face.vertIndices[0], face.vertIndices[1], face.vertIndices[2], face.vertIndices[3]]

                result.append(ObjFace(vertIndices: [
                    temp[startIndex],
                    temp[(startIndex + 1) % 4],
                    temp[(startIndex + 2) % 4],
                ]))

                result.append(ObjFace(vertIndices: [
                    temp[startIndex],
                    temp[(startIndex + 2) % 4],
                    temp[(startIndex + 3) % 4],
                ]))
            } else {
                throw Error.unsupportedFace(face.vertIndices.count)
            }
        }
        
        return result
    }
    
    // https://github.com/assimp/assimp/blob/master/code/PostProcessing/CalcTangentsProcess.cpp
    /// Generate tangents and bitangents
    private func generateTangents() throws {
        if faces[0].vertIndices.count != 3 {
            throw Error.noTangentsForNonTriangle
        }
        
        if vertices[faces[0].vertIndices[0]].normal == 0 || vertices[faces[0].vertIndices[0]].texCoord == 0 {
            throw Error.noNormalsOrUvs
        }
        
        // Phase 1: generate tangent and bitangent based on normal and texcoords
        for face in faces {
            let p0 = vertices[face.vertIndices[0]]
            let p1 = vertices[face.vertIndices[1]]
            let p2 = vertices[face.vertIndices[2]]
            
            // Position difference
            let v = positions[p1.position - 1] - positions[p0.position - 1]
            let w = positions[p2.position - 1] - positions[p0.position - 1]
            
            var s = texCoords[p1.texCoord - 1] - texCoords[p0.texCoord - 1]
            var t = texCoords[p2.texCoord - 1] - texCoords[p0.texCoord - 1]

            let dirCorrection: Float = (t.x * s.y - t.y * s.x) < 0.0 ? -1 : 1;

            if s.x * t.y == s.y * t.x {
                s = [0, 1]
                t = [1, 0]
            }

            let tangent = (w * s.y - v * t.y) * dirCorrection
            let bitangent = (w * s.x - v * t.x) * dirCorrection

            for vertIndex in face.vertIndices {
                let normal = normals[vertices[vertIndex].normal - 1]
                
                var localTangent = normalize(tangent - normal * (tangent * normal))
                var localBitangent = normalize(bitangent - normal * (bitangent * normal))

                let invalidTangent = localTangent.x.isNaN || localTangent.y.isNaN || localTangent.z.isNaN
                let invalidBitangent = localBitangent.x.isNaN || localBitangent.y.isNaN || localBitangent.z.isNaN

                if invalidTangent != invalidBitangent {
                    if invalidTangent {
                        localTangent = normalize(cross(normal, localBitangent))
                    } else {
                        localBitangent = normalize(cross(localTangent, normal))
                    }
                }

                vertices[vertIndex].tangent = localTangent
                vertices[vertIndex].bitangent = localBitangent
            }
        }
        
        // Phase 2: smoothing
        // https://github.com/assimp/assimp/blob/master/code/PostProcessing/CalcTangentsProcess.cpp#L239
        
        let (boundsMax, boundsMin) = vertices
            .map { positions[$0.position - 1] }
            .reduce((float3(Float.infinity, Float.infinity, Float.infinity), float3(-Float.infinity, -Float.infinity, -Float.infinity))) {
                (min($0.0, $1), max($0.1, $1))
        }
        
        let posEpsilon: Float = length(boundsMax - boundsMin) * Float(1e-4)
        let angleEpsilon: Float = 0.9999
        let fLimit: Float = cos(Float(45).degreesToRadians) // TODO: configurable
        
        let spatialFinder = SpatialFinder(vertices.map { positions[$0.position - 1] })
        var done = Set<Int>()
        
        for (vertexIndex, vertex) in vertices.enumerated() {
            if done.contains(vertexIndex) {
                continue
            }

            // get position, normal, tangent, bitangent
            let position = positions[vertex.position - 1]
            let normal = normals[vertex.normal - 1]
            let tangent = vertex.tangent
            let bitangent = vertex.bitangent
            
            // Find any vertices near to what we are
            let nearVertices = spatialFinder.near(position, radius: posEpsilon)
            
            // List of vertices that are both near and like the current vertex
            var closeVertices: [Int] = [vertexIndex]

            // Look at the near vertices
            for nearVertex in nearVertices {
                let vertex = vertices[nearVertex]
                
                if done.contains(nearVertex) {
                    continue
                }
                
                if dot(normals[vertex.normal - 1], normal) < angleEpsilon {
                    continue
                }
                if dot(vertex.tangent, tangent) < fLimit {
                    continue
                }
                if dot(vertex.bitangent, bitangent) < fLimit {
                    continue
                }
                
                closeVertices.append(nearVertex)
                done.insert(nearVertex)
            }
            
            // Average the values of each close vertex
            var smoothTangent = float3(0, 0, 0)
            var smoothBitangent = float3(0, 0, 0)
            
            for closeIndex in closeVertices {
                smoothTangent += vertices[closeIndex].tangent
                smoothBitangent += vertices[closeIndex].bitangent
            }
            smoothTangent = normalize(smoothTangent)
            smoothBitangent = normalize(smoothBitangent)

            for closeIndex in closeVertices {
                vertices[closeIndex].tangent = smoothTangent
                vertices[closeIndex].bitangent = smoothBitangent
                done.insert(closeIndex)
            }
        }
    }
}
