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
    var positions: [float3] = []
    var normals: [float3] = []
    var texCoords: [float2] = []
    var faces: [ObjFace] = []
    
    enum Error: Swift.Error {
        case invalidFace(Substring, SourceLocation)
        
        /// The face is not supported
        case unsupportedFace(Int, SourceLocation)
        
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
        print("[obj] Starting group \(name)")
        
        currentGroup = name
        faces = []
    }
    
    func finishSubmesh() throws {
        if faces.count == 0 {
            // Some obj files put all vertex data in a group, and then build faces per actual group
            print("[obj] Found group with no faces. Skipping.")
            return
        }
        
        let name = (currentObject ?? "") + (currentGroup ?? "default")
        
        // Triangulate all meshes
        try triangulate()
        
        // Save time by not always generating
        if shouldGenerateTangents {
            try generateTangents()
        }
        
        print("[obj] Building submesh with name \(name), faces \(faces.count), material \(String(describing: currentMaterial))")
        obj.submeshes.append(ObjSubmesh(name: name, material: currentMaterial, faces: faces))
    }
    
    // https://github.com/assimp/assimp/blob/master/code/PostProcessing/TriangulateProcess.cpp#L227
    /// Triangulate the faces. Supports triangles (no conversion) and quads (fast conversion)
    private func triangulate() throws {
        var result: [ObjFace] = []

        for face in faces {
            if face.vertices.count == 3 {
                result.append(face)
            } else if face.vertices.count == 4 {
                var startIndex = 0
                
                for i in 0..<4 {
                    let v0 = positions[face.vertices[(i + 3) % 4].position - 1] // obj is 1-indexed
                    let v1 = positions[face.vertices[(i + 2) % 4].position - 1]
                    let v2 = positions[face.vertices[(i + 1) % 4].position - 1]
                    let v = positions[face.vertices[i].position - 1]
                    
                    let left = normalize(v0 - v)
                    let diag = normalize(v1 - v)
                    let right = normalize(v2 - v)
                    
                    let angle = acos(dot(left, diag)) + acos(dot(right, diag))
                    if angle > π {
                        startIndex = i
                        break
                    }
                }
                
                let temp = [face.vertices[0], face.vertices[1], face.vertices[2], face.vertices[3]]
                
                result.append(ObjFace(vertices: [
                    temp[startIndex],
                    temp[(startIndex + 1) % 4],
                    temp[(startIndex + 2) % 4],
                ]))
                
                result.append(ObjFace(vertices: [
                    temp[startIndex],
                    temp[(startIndex + 2) % 4],
                    temp[(startIndex + 3) % 4],
                ]))
            } else {
                throw Error.unsupportedFace(face.vertices.count, offsetToLocation(offset))
            }
        }
        
        faces = result
    }
    
    // https://github.com/assimp/assimp/blob/master/code/PostProcessing/CalcTangentsProcess.cpp
    /// Generate tangents and bitangents
    private func generateTangents() throws {
        if faces[0].vertices.count != 3 {
            throw Error.noTangentsForNonTriangle
        }
        
        if faces[0].vertices[0].normal == 0 || faces[0].vertices[0].texCoord == 0 {
            throw Error.noNormalsOrUvs
        }
        
        for (faceIndex, face) in faces.enumerated() {
            let p0 = face.vertices[0]
            let p1 = face.vertices[1]
            let p2 = face.vertices[2]
            
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

            for (index, vertex) in face.vertices.enumerated() {
                let normal = normals[vertex.normal - 1]
                
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

                faces[faceIndex].vertices[index].tangent = localTangent
                faces[faceIndex].vertices[index].bitangent = localBitangent
            }
        }
        
        let posEpsilon: Float = 10e-6
        let angleEpsilon: Float = 0.9999
        // https://github.com/assimp/assimp/blob/master/code/PostProcessing/CalcTangentsProcess.cpp#L239
        
        // bitangent = cross(normal, tangent.xyz) * tangent.w
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
            .map { try vertex(input: $0) }
            
        return ObjFace(vertices: verts)
    }
}
