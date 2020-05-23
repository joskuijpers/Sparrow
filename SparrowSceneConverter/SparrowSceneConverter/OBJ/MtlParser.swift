//
//  MtlParser.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

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
        
        print("[mtl] Found \(lib.materials.count) materials of which \(Set(lib.materials).count) unique")
        
        return lib
    }
    
    /// Read a line
    private func line() {
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
            currentMaterial?.hasAlpha = true
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
            currentMaterial?.hasAlpha = true
        case .none:
            print("[mtl] Could not read action at \(offsetToLocation(offset))")
        default:
            print("[mtl] Unhandled action: \(action!) at \(offsetToLocation(offset))")
            skipLine()
        }
        
        // Skip newline at the end
        skipNewlines()
    }
    
    /// Parse a texture into a full path
    private func texture() -> URL {
        return URL(fileURLWithPath: URL(string: String(text()), relativeTo: url)!.path)
//        return URL(string: String(text()), relativeTo: url)
    }
}
