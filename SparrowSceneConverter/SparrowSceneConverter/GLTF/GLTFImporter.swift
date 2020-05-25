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
        
        let importer = try GLTFImporter(inputUrl: url, outputUrl: outputUrl, generateTangents: generateTangents, uniformScale: uniformScale)
        let asset = try importer.generate()
        
        return SAFileRef(url: outputUrl, asset: asset)
    }
}

private extension GLTFImporter {
    
    /// Generate the asset
    func generate() throws -> SAAsset {
    
        let allocator = GLTFSAAllocator()
        let inAsset = GLTFAsset(url: inputUrl, bufferAllocator: allocator)
        
        print(inAsset)
        
        
        return SAAsset(generator: "SparrowSceneConverter", origin: inputUrl.path)
    }
}

final class GLTFSAAllocator: GLTFBufferAllocator {
    static func liveAllocationSize() -> UInt64 {
        print("Get live allocation size")
        return 0
    }
    
    func newBuffer(withLength length: Int) -> GLTFBuffer {
        print("Create new buffer of size \(length)")
        
        let buffer = SABuffer(data: Data(capacity: length))
        return GLTFSABuffer(underlying: buffer)
    }
    
    func newBuffer(with data: Data) -> GLTFBuffer {
        print("Create new buffer of data \(data)")
        
        let buffer = SABuffer(data: data)
        return GLTFSABuffer(underlying: buffer)
    }
}

final class GLTFSABuffer: GLTFBuffer {
    let underlying: SABuffer
    
    var name: String? = nil
    var extensions: [AnyHashable : Any] = [:]
    var extras: [AnyHashable : Any] = [:]
    
    var length: Int {
        return underlying.data.count
    }
    
    var contents: UnsafeMutableRawPointer {
        var data = underlying.data
        
        return data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) -> UnsafeMutableRawPointer in
            print("GET MUTABLE BYTES")
            return UnsafeMutableRawPointer(ptr)
        }
    }
    
    init(underlying: SABuffer) {
        self.underlying = underlying
    }
    
    deinit {
        print("Dealloc buffer")
    }
}
