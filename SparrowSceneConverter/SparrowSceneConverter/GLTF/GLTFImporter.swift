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

class GltfImporter {
    private let inputUrl: URL
    private let outputUrl: URL
    private let generateTangents: Bool
    //    private let positionScale: Float
    
    private let textureTool: TextureTool
    private let objectName: String
    
    enum Error: Swift.Error {
        /// The ObjImporter only supports .obj files.
        case fileFormatNotSupported
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
        
        let importer = try GltfImporter(inputUrl: url, outputUrl: outputUrl, generateTangents: generateTangents, uniformScale: uniformScale)
        let asset = try importer.generate()
        
        return SAFileRef(url: outputUrl, asset: asset)
    }
}

private extension GltfImporter {
    
    /// Generate the asset
    func generate() throws -> SAAsset {
    
        
        return SAAsset(generator: "SparrowSceneConverter", origin: inputUrl.path)
    }
}
