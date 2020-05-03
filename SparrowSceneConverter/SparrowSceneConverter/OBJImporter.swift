//
//  OBJImporter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

class OBJImporter {
    let url: URL
    var objFile: ObjFile?
    var mtlFile: MtlFile?
    
    init(url: URL) {
        guard url.pathExtension == "obj" else {
            fatalError("OBJ importer only supports .obj files")
        }
        
        self.url = url
    }
    
    /// Generate the asset
    func generate() throws -> SAAsset {
        let objParser = try ObjParser(url: url)
        objFile = try objParser.parse()
        
        if let mtlPath = objFile?.mtllib,
            let mtlUrl = URL(string: mtlPath, relativeTo: url) {
            let mtlParser = try MtlParser(url: mtlUrl)
            mtlFile = try mtlParser.parse()
        }
        
        return buildAsset()
    }
    
    /// Build asset from values in memory
    private func buildAsset() -> SAAsset {
        print("Build asset from \(String(describing: objFile)) \(String(describing: mtlFile))")
        
        return SAAsset(generator: "SparrowSceneConverter", origin: url.path, version: 1)
    }
    
    
    func x() {
        
        // Build index buffer
        struct VertexBufferItem: Hashable {
            let vertex: float3
            let normal: float3
            let tangent: float3
            let bitangent: float3
            let uv: float2
            
            
        }
        
        var min = float3(Float.infinity, Float.infinity, Float.infinity)
        var max = float3(-Float.infinity, -Float.infinity, -Float.infinity)
        
        var vertexBuffer: [VertexBufferItem] = []
        var indexBuffer: [Int] = []
        
        // For each submesh
            // indexBuffer = []
        
            // For each face
                // For each vertex
                    // Add full vertex to vertex list
                    // Add index to index buffer
        
            // Create material
            // put index buffer with submesh + name + material
        // put vertex buffer with mesh
        
        
        // make unique
        // walk over all vertices
            // if does not exist yet, add to list
            // if exists, point to it instead
            // needs hashable: [Vertex: Int] for quickly finding
        
        // put all buffers behind each other, create buffer views
    }
}

struct ObjFile {
    var mtllib: String?
    
    var vertices: [float3] = []
    var normals: [float3] = []
    var texCoords: [float2] = []
    var submeshes: [ObjSubmesh] = []
}

struct MtlFile {
    var materials: [MtlMaterial] = []
}

struct MtlMaterial {
    let name: String
    
    var albedoColor: float3 = float3(0, 0, 0)
    var roughness: Float = 0
    var metallic: Float = 0
    var alpha: Float = 1
    var emissiveColor: float3 = float3(0, 0, 0)
    
    var albedoTexture: URL?
    var normalTexture: URL?
    var roughnessTexture: URL?
    var metallicTexture: URL?
    var aoTexture: URL?
    var emissiveTexture: URL?
    var alphaTexture: URL?
}

struct ObjFace {
    var vertices: [ObjVertex]
}

struct ObjVertex {
    var vertex: Int
    var normal: Int
    var texCoord: Int
}

struct ObjSubmesh {
    let name: String
    let material: String?
    let faces: [ObjFace]
}

class StructuredTextParser {
    var source: String
    var index: String.Index
    var input: String.UnicodeScalarView
    var offset = 0
    
    let whitespaceSet = CharacterSet.whitespaces
    let identifierSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    let textSet = CharacterSet.alphanumerics.union(.punctuationCharacters)
    let floatSet = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".-"))
    let whitespaceNewlineSet = CharacterSet.whitespacesAndNewlines
    
    init(input: String) {
        self.input = input.unicodeScalars
        self.index = input.startIndex
        self.source = input
    }
    
    func char() -> Character? {
        let v = input[index]
        
        index = input.index(after: index)
        
        return Character(v)
    }
    
    // Find a valid identifier with a space behind it
    func identifier() -> Substring? {
        var newIndex = index
        var newOffset = offset

        while newIndex < input.endIndex, identifierSet.contains(input[newIndex]) {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }

        let result = source[index..<newIndex]
        index = newIndex
        offset = newOffset
        skipWhitespace()
        
        return result
    }
    
    /// Match with a string and consume
    func consume(_ string: String) -> Bool {
        let scalars = string.unicodeScalars
        var newOffset = offset
        var newIndex = index
        
        for c in scalars {
            guard newIndex < input.endIndex, input[newIndex] == c else {
                return false
            }
            newOffset += 1
            newIndex = input.index(after: newIndex)
        }
        
        // Matched
        index = newIndex
        offset = newOffset

        return true
    }
    
    /// Match a character without consuming
    func match(_ char: Unicode.Scalar) -> Bool {
        return input[index] == char
    }
    
    /// Match any text until the next space
    func text() -> Substring {
        var newIndex = index
        var newOffset = offset

        while textSet.contains(input[newIndex]), index < input.endIndex {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }
        
        let result = source[index..<newIndex]
        index = newIndex
        offset = newOffset
        skipWhitespace()
        
        return result
    }
    
    /// Skip any whitespace
    func skipWhitespace() {
        while index < input.endIndex, whitespaceSet.contains(input[index]) {
            index = input.index(after: index)
            offset += 1
        }
    }
    
    /// Skip everything until a newline
    func skipLine() {
        while index < input.endIndex, input[index] != "\n" {
            index = input.index(after: index)
            offset += 1
        }
        skipNewlines()
    }
    
    func skipWhitespaceAndNewlines() {
        while index < input.endIndex, whitespaceNewlineSet.contains(input[index]) {
            index = input.index(after: index)
            offset += 1
        }
    }
    
    /// Skip newlines
    func skipNewlines() {
        while index < input.endIndex, input[index] == "\n" {
            index = input.index(after: index)
            offset += 1
        }
    }
    
    /// Parse a single floating point value
    func parseFloat1() -> Float {
        var newIndex = index
        var newOffset = offset
        
        while floatSet.contains(input[newIndex]), index < input.endIndex {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }
        
        let result = source[index..<newIndex]
        if let f = Float(result) {
            index = newIndex
            offset = newOffset
            
            skipWhitespace()
            
            return f
        }
            
        fatalError("Could not parse float1 at \(offsetToLocation(offset))")
    }
    
    /// Parse two floating point values separated by a space
    func parseFloat2() -> float2 {
        return float2(parseFloat1(), parseFloat1())
    }
    
    /// Parse three floating point values separated by a space
    func parseFloat3() -> float3 {
        return float3(parseFloat1(), parseFloat1(), parseFloat1())
    }
    
    func restOfLine() -> Substring {
        var newIndex = index
        var newOffset = offset

        while index < input.endIndex, input[newIndex] != "\n" {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }
        
        let result = source[index..<newIndex]
        index = newIndex
        offset = newOffset
        
        skipWhitespace()
        
        return result
    }
    
    
    /// Find location for offset
    func offsetToLocation(_ search: Int) -> SourceLocation {
        var line = 0
        var column = 0
        var index = input.startIndex
        var offset = 0
        
        while index < input.endIndex {
            if offset == search {
                return SourceLocation(line: line, column: column)
            }
            
            if input[index] == "\n" {
                line += 1
                column = 0
            } else {
                column += 1
            }
            
            index = input.index(after: index)
            offset += 1
        }
        
        return SourceLocation(line: -1, column: -1)
    }
    
    struct SourceLocation: CustomStringConvertible {
        let line: Int
        let column: Int
        
        var description: String {
            if line == -1 && column == -1 {
                return "?:?"
            }
            return "\(line + 1):\(column + 1)"
        }
    }
}

class ObjParser: StructuredTextParser {
    let url: URL
    var obj = ObjFile()
    var currentMaterial: String?
    var currentGroup: String?
    var currentObject: String?
    var vertices: [float3] = []
    var normals: [float3] = []
    var texCoords: [float2] = []
    var faces: [ObjFace] = []
    
    init(url: URL) throws {
        self.url = url
        
        let input = try String(contentsOf: url)
        super.init(input: input)
    }
    
    func parse() throws -> ObjFile {
        while index < input.endIndex {
            line()
        }
        
        if currentGroup != nil {
            finishSubmesh()
        }
        
        obj.vertices = vertices
        obj.normals = normals
        obj.texCoords = texCoords
        
        return obj
    }
    
    /// Read a line
    func line() {
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
                finishSubmesh()
            }
            startSubmesh(name: name)
            
        case "o": // Has no effect
            currentObject = String(text())
        case "usemtl":
            currentMaterial = String(text())
            
        case "v":
            vertices.append(parseFloat3())
        case "vn":
            normals.append(parseFloat3())
        case "vt":
            texCoords.append(parseFloat2())
        case "f":
            faces.append(face())
            
        case "s": // Not used in Sparrow
            skipLine()
            
        case .none:
            print("Could not read action at \(offsetToLocation(offset))")
        default:
            print("Unhandled action: \(action!) at \(offsetToLocation(offset))")
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
    
    func finishSubmesh() {
        if faces.count == 0 {
            // Some obj files put all vertex data in a group, and then build faces per actual group
            print("[obj] Found group with no faces. Skipping.")
            return
        }
        
        let name = (currentObject ?? "") + (currentGroup ?? "default")
        
        // Triangulate all meshes
        triangulate()
        
        print("[obj] Building submesh with name \(name), faces \(faces.count), material \(String(describing: currentMaterial))")
        obj.submeshes.append(ObjSubmesh(name: name, material: currentMaterial, faces: faces))
    }
    
    /// Triangulate the faces
    // https://github.com/assimp/assimp/blob/master/code/PostProcessing/TriangulateProcess.cpp#L227
    func triangulate() {
        var result: [ObjFace] = []

        for face in faces {
            if face.vertices.count == 3 {
                result.append(face)
            } else if face.vertices.count == 4 {
                var startIndex = 0
                
                for i in 0..<4 {
                    let v0 = vertices[face.vertices[(i + 3) % 4].vertex - 1] // obj is 1-indexed
                    let v1 = vertices[face.vertices[(i + 2) % 4].vertex - 1]
                    let v2 = vertices[face.vertices[(i + 1) % 4].vertex - 1]
                    let v = vertices[face.vertices[i].vertex - 1]
                    
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
                fatalError("[obj] No support for faces with \(face.vertices.count) vertices")
            }
        }
        
        faces = result
    }
    
    /// Parse a vertex of a face
    func vertex(input: Substring) -> ObjVertex {
        let items = input.split(separator: "/")
        
        if items.count != 3 {
            fatalError("Could not read face at \(offsetToLocation(offset))")
        }
        
        let vert = Int(items[0])!
        let tex = Int(items[1])!
        let norm = Int(items[2])!
        
        return ObjVertex(vertex: vert, normal: norm, texCoord: tex)
    }
    
    /// Parse a face. Might give 2 faces when turning a quad into a triangle
    func face() -> ObjFace {
        let verts = restOfLine()
            .split(separator: " ")
            .map { vertex(input: $0) }
            
        return ObjFace(vertices: verts)
    }
}

class MtlParser: StructuredTextParser {
    let url: URL
    var lib = MtlFile()
    
    private var currentMaterial: MtlMaterial?
    
    init(url: URL) throws {
        self.url = url
        
        let input = try String(contentsOf: url)
        super.init(input: input)
    }
    
    /// Parse the file by handling line for line
    func parse() throws -> MtlFile {
        // Must be fresh so parse can be called multiple times
        lib = MtlFile()
        
        while index < input.endIndex {
            line()
        }
        
        // Add last parsed material
        if let mat = currentMaterial {
            lib.materials.append(mat)
        }
        
        print("[mtl] Found \(lib.materials.count) materials")
        
        return lib
    }
    
    /// Read a line
    func line() {
        // Skip comments
        while match("#") {
            skipLine()
        }

        // Whitespace can precede an identifier
        skipWhitespaceAndNewlines()
        
        let action = identifier()
        
        switch action {
        case "newmtl":
            if let mat = currentMaterial {
                lib.materials.append(mat)
            }
            currentMaterial = MtlMaterial(name: String(text()))
            
        case "Kd":
            currentMaterial?.albedoColor = parseFloat3()
        case "Ke":
            currentMaterial?.emissiveColor = parseFloat3()
            
        case "metallic":
            currentMaterial?.metallic = parseFloat1()
        case "roughness":
            currentMaterial?.roughness = parseFloat1()
        case "Ka", "Pm":
            currentMaterial?.metallic = parseFloat3().x
        case "Ks", "Pr":
            currentMaterial?.roughness = parseFloat3().x
            
        case "d":
            currentMaterial?.alpha = parseFloat1()
        case "illum", "Ns", "Ni", "Tr", "Tf":
            // Unhandled
            skipLine()
            break
            
            
        case "map_ao":
            currentMaterial?.aoTexture = texture()
        case "map_Ka", "map_metallic", "map_Pm":
            currentMaterial?.metallicTexture = texture()
        case "map_Kd", "map_albedo": // Albedo
            currentMaterial?.albedoTexture = texture()
        case "map_Ns", "map_roughness", "map_Pr":
            currentMaterial?.roughnessTexture = texture()
        case "norm", "bump", "map_bump", "map_Kn", "map_tangentSpaceNormal":
            currentMaterial?.normalTexture = texture()
        case "map_Ke":
            currentMaterial?.emissiveTexture = texture()
        case "map_d":
            currentMaterial?.alphaTexture = texture()
        case .none:
            print("Could not read action at \(offsetToLocation(offset))")
        default:
            print("Unhandled action: \(action!) at \(offsetToLocation(offset))")
            skipLine()
        }
        
        // Skip newline at the end
        skipNewlines()
    }
    
    func texture() -> URL {
        return URL(fileURLWithPath: URL(string: String(text()), relativeTo: url)!.path)
//        return URL(string: String(text()), relativeTo: url)
    }
}
