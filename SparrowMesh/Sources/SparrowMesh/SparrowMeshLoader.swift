//
//  SparrowMeshLoader.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

/**
 Asset load for SparrowMesh (.spm) files.
 */
public class SparrowMeshLoader {
    private let data: Data
    
    enum Error: Swift.Error {
        /// The file is not a valid asset
        case invalidAssetFormat
        
        /// The version of the asset does not match the version of the code.
        case invalidAssetVersion
        
        /// The file is incomplete or broken
        case brokenFile(Swift.Error)
        
        /// The checksum was not valid.
        case invalidChecksum
        
        /// The extension was not `spm`.
        case invalidExtension(String)
    }
    
    private init(data: Data) {
        self.data = data
    }
    
    private func load() throws -> SAAsset {
        let bytes = [UInt8](data)
        
        // Check if data > header size
        if bytes.count <= MemoryLayout<SPMFileHeader>.size {
            throw Error.invalidAssetFormat
        }
        
        // Verify header indication
        let validHeader = try BinaryEncoder.encode(SPMFileHeaderIndicator())
        if Array(bytes[0..<validHeader.count]) != validHeader {
            throw Error.invalidAssetFormat
        }
        
        // Read header. Check version. Do not assume the rest of the file is decodable
        let version = try BinaryDecoder.decode(SPMFileHeader.SPMFileVersion.self, data: [bytes[3]])
        if version != .version1 { // TODO: PUT HIS 1 SOMEWHERE
            throw Error.invalidAssetVersion
        }

        var asset: SAAsset!
        do {
            // Read the whole file
            asset = try BinaryDecoder.decode(SAAsset.self, data: bytes)
        } catch {
            throw Error.brokenFile(error)
        }
        // `asset` will never be nil: it will either be a value or brokenFile has thrown
        
        if !asset.verifyChecksum() {
            throw Error.invalidChecksum
        }
        
        return asset
    }
    
    /// Load an asset from given URL.
    public static func load(from url: URL) throws -> SAFileRef {
        if url.pathExtension != "spm" {
            throw Error.invalidExtension(url.pathExtension)
        }
        
        let data = try Data(contentsOf: url, options: .dataReadingMapped)
        let loader = SparrowMeshLoader(data: data)

        let asset = try loader.load()
        
        return SAFileRef(url: url, asset: asset)
    }
    
    /// Load an asset from given Data.
    public static func load(from data: Data) throws -> SAAsset {
        let loader = SparrowMeshLoader(data: data)

        return try loader.load()
    }
}
