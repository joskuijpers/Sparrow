//
//  SparrowAssetLoader.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/**
 Asset load for SparrowAsset (.sa) files.
 */
public class SparrowAssetLoader {
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
        
        /// The extension was not `sa`.
        case invalidExtension(String)
    }
    
    private init(data: Data) {
        self.data = data
    }
    
    private func load() throws -> SAAsset {
        let bytes = [UInt8](data)
        
        // Check if data > header size
        if bytes.count <= MemoryLayout<SAFileHeader>.size {
            throw Error.invalidAssetFormat
        }
        
        // Verify header indication
        let validHeader = try BinaryEncoder.encode(SAFileHeaderIndicator())
        if Array(bytes[0..<validHeader.count]) != validHeader {
            throw Error.invalidAssetFormat
        }
        
        // Read header. Check version. Do not assume the rest of the file is decodable
        let version = try BinaryDecoder.decode(SAFileHeader.SAFileVersion.self, data: [bytes[3]])
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
    public static func load(from url: URL) throws -> SAAsset {
        if url.pathExtension != "sa" {
            throw Error.invalidExtension(url.pathExtension)
        }
        
        let data = try Data(contentsOf: url, options: .dataReadingMapped)
        let loader = SparrowAssetLoader(data: data)

        return try loader.load()
    }
    
    /// Load an asset from given Data.
    public static func load(from data: Data) throws -> SAAsset {
        let loader = SparrowAssetLoader(data: data)

        return try loader.load()
    }
}
