//
//  OBJImporter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

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
}

struct ObjFile {
    var mtllib: String?
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

class StructuredTextParser {
    var source: String
    var index: String.Index
    var input: String.UnicodeScalarView
    var offset = 0
    
    let whitespaceSet = CharacterSet.whitespaces
    let identifierSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    let textSet = CharacterSet.alphanumerics.union(.punctuationCharacters)
    let floatSet = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
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
            
        fatalError("Could not parse float1")
    }
    
    /// Parse two floating point values separated by a space
    func parseFloat2() -> float2 {
        return float2(parseFloat1(), parseFloat1())
    }
    
    /// Parse three floating point values separated by a space
    func parseFloat3() -> float3 {
        return float3(parseFloat1(), parseFloat1(), parseFloat1())
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
    
    init(url: URL) throws {
        self.url = url
        
        print(url.path)
        
        let input = try String(contentsOf: url)
        super.init(input: input)
    }
    
    func parse() throws -> ObjFile {
        while index < input.endIndex {
            line()
        }
        
        return obj
    }
    
    /// Read a line
    func line() {
        // Skip comments
        while match("#") {
            skipLine()
        }
        
        skipWhitespaceAndNewlines()
        
        let action = identifier()
        
        switch action {
        case "mtllib":
            obj.mtllib = String(text())
        default:
//            print("Unhandled action: \(action)")
            skipLine()
        }
        
        // Skip newline at the end
        skipNewlines()
    }
}

        // mtllib <path>
        
//        o <name> -> keep state
//        v float3    vertex
//        vt float2   texCoord0
//        vn float3  normals
//        g <name> ??? group? submesh name --> <object>_<group>
//        usemtl <name>
//        s <1/0>
//        f (v/t/n){3}

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
        while index < input.endIndex {
            line()
        }
        
        // Add last parsed material
        if let mat = currentMaterial {
            lib.materials.append(mat)
        }
        
        print("Found \(lib.materials.count) materials")
        
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
        case "Ka":
            currentMaterial?.metallic = parseFloat3().x
        case "Ks":
            currentMaterial?.roughness = parseFloat3().x
            
        case "d":
            currentMaterial?.alpha = parseFloat1()
        case "illum", "Ns", "Ni", "Tr", "Tf":
            // Unhandled
            skipLine()
            break
            
            
        case "map_ao":
            currentMaterial?.aoTexture = texture()
        case "map_Ka", "map_metallic":
            currentMaterial?.metallicTexture = texture()
        case "map_Kd", "map_albedo": // Albedo
            currentMaterial?.albedoTexture = texture()
        case "map_Ns", "map_roughness":
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
    
    //        newmtl <name>
    //        Ns Ni d Tr Tf illum
    //        Ka Kd Ks Ke float3
    //        map_Ka/map_metallic <path>
    //        map_Kd/map_albedo <path>
    //        map_d <path>
    //        map_bump/map_norm/bump <path>
    //        map_Ns/map_roughness <path>
    //        map_Ke <path> emissive
}
