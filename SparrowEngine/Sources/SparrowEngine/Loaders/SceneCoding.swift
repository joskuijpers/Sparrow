//
//  SceneCoding.swift
//  
//
//  Created by Jos Kuijpers on 15/06/2020.
//

import Foundation
import SparrowECS
import SparrowSafeBinaryCoder
import Compression

/// Loader and writier of scene files (.sps).
///
/// Loading results in a hierarchy of entities with components.
/// Entities might have mesh components. These will already be loaded.
public class SceneCoding {

    enum Error: Swift.Error {
        /// Checksum in the file was not valid
        case invalidChecksum
        
        /// Compressing the coding failed.
        case compressionFailed
    }
    
    public init() {}
    
    /// Load the entities from given file into the world.
    ///
    /// - Returns: the entities loaded.
    public func load(from path: URL, into world: World) throws -> [Entity] {
        let data = try readCompressed(url: path)
        
        let file = try SafeBinaryDecoder.decode(SPSFile.self, data: data)
        
        if !file.verifyChecksum() {
            throw Error.invalidChecksum
        }

        let entities = try world.nexus.decode(data: file.nexus)

        // Did decode notifications
        for entity in entities {
            for componentIdentifier in world.nexus.get(components: entity.identifier)! {
                if let component = world.nexus.get(component: componentIdentifier, for: entity.identifier),
                    let custom = component as? ComponentStorageDelegate {
                    try custom.didDecode(into: world)
                }
            }
        }
        
        return entities
    }
    
    /// Save given entities to a file.
    public func save(entities: [Entity], in world: World, to path: URL, generator: String = "SparrowEngine", origin: String? = nil) throws {
        // Will encode notifications
        for entity in entities {
            for componentIdentifier in world.nexus.get(components: entity.identifier)! {
                if let component = world.nexus.get(component: componentIdentifier, for: entity.identifier),
                    let storable = component as? NexusStorable,
                    Nexus.getRegistered(identifier: storable.stableIdentifier) != nil,
                    let custom = storable as? ComponentStorageDelegate {
                    
                    try custom.willEncode(from: world)
                }
            }
        }
        
        let nexusBytes = try world.nexus.encode(entities: entities)

        var file = SPSFile(header: SPSFileHeader(generator: generator, origin: origin), nexus: Data(nexusBytes))
        file.updateChecksum()
        
        let data = try SafeBinaryEncoder.encode(file)
    
        try writeCompressed(url: path, data: data)
        
        print("Encoded scene size: \(data.count) bytes, size on disk: \(try FileManager.default.attributesOfItem(atPath: path.path)[FileAttributeKey.size] as! UInt64) bytes")
    }
    
    /// Read data from the url and decompress it.
    private func readCompressed(url: URL) throws -> Data {
//        print("SCRATCH", compression_encode_scratch_buffer_size(COMPRESSION_LZFSE))
        // TODO: We could pre-allocate a scratch buffer during the lifetime of the game
        
        // Read data
        let compressedData = try Data(contentsOf: url)
        
        // Get the Int at the end for decompressed size
        var decompressedSize = Int()
        compressedData.withUnsafeBytes {
            let byteCount = MemoryLayout<Int>.size
            let cursor = compressedData.count - byteCount
            let from = $0.baseAddress! + cursor
            memcpy(&decompressedSize, from, byteCount)
        }
        
        // Allocate buffer
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompressedSize)
        
        // Decompress and gain final size
        let size = compressedData.withUnsafeBytes { (ptr) -> Int in
            compression_decode_buffer(destinationBuffer,
                                      decompressedSize,
                                      ptr.bindMemory(to: UInt8.self).baseAddress!,
                                      compressedData.count - MemoryLayout<Int>.size,
                                      nil,
                                      COMPRESSION_LZFSE)
        }
        
        if size == 0 {
            throw Error.compressionFailed
        }
        
        // Make a Data
        let decompressedData = Data(bytesNoCopy: destinationBuffer, count: size, deallocator: .custom({ (_, _) in
            destinationBuffer.deallocate()
        }))

        return decompressedData
    }
    
    /// Write the data compressed to given  url
    private func writeCompressed(url: URL, data: Data) throws {
        let decompressedSize = data.count

        // We are compressing and assume we never go larger than our original size
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompressedSize)
        
        // print(compression_decode_scratch_buffer_size(COMPRESSION_LZFSE))
        // TODO: We could pre-allocate a scratch buffer during the lifetime of the game
        
        let size = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int in
            compression_encode_buffer(destinationBuffer,
                                      decompressedSize,
                                      ptr.bindMemory(to: UInt8.self).baseAddress!,
                                      decompressedSize,
                                      nil,
                                      COMPRESSION_LZFSE)
        }
        
        if size == 0 {
            throw Error.compressionFailed
        }

        // Make a Data
        var compressedData = Data(bytesNoCopy: destinationBuffer, count: size, deallocator: .custom({ (_, _) in
            destinationBuffer.deallocate()
        }))
        
        // Append the size of the decompressed data
        withUnsafeBytes(of: decompressedSize) {
            compressedData.append(contentsOf: $0)
        }
        
        try compressedData.write(to: url)
    }
}

fileprivate struct SPSFile: Codable {
    /// File header with indicator, version, generator, and origin.
    let header: SPSFileHeader
    
    /// File checksum.
    ///
    /// Composed of the sizes of the content lists.
    private var checksum: UInt = 0
    
    /// Nexus coded data.
    let nexus: Data
    
    init(header: SPSFileHeader, nexus: Data) {
        self.header = header
        self.nexus = nexus
    }
}

extension SPSFile {
    /// Update the checksum to match the content.
    public mutating func updateChecksum() {
        checksum = generateChecksum()
    }
    
    /// Generate the checksum from the content.
    private func generateChecksum() -> UInt {
        var checksum: UInt = 0
        
        checksum = checksum * 11 + UInt(nexus.count)
        
        for b in nexus.prefix(10) {
            checksum = checksum * 11 + UInt(b)
        }
        
        return checksum
    }
    
    /// Get whether the checksum is valid for the content.
    public func verifyChecksum() -> Bool {
        return checksum == generateChecksum()
    }
}

/// Sparrow Asset file header.
fileprivate struct SPSFileHeader: Codable {
    /// Indicator of the SparrowAsset file: a prefix.
    private(set) var indicator = SPSFileHeaderIndicator() // Must be a var so codable can override it
    
    /// Version of the file format
    private(set) var version: SPSFileVersion = .version1
    
    /// The generator used to generate the file.
    let generator: String
    
    /// The origin of the data used to generate the file. Useful for re-generation
    let origin: String
    
    /// The version of the asset file format
    enum SPSFileVersion: UInt8, Codable {
        case version1 = 1
    }
    
    /// Create a header.
    init(generator: String, origin: String?) {
        self.generator = generator
        self.origin = origin ?? ""
    }
}

/// File header indicator: 3 bytes 'SPM '
fileprivate struct SPSFileHeaderIndicator: Codable {
    // A string has a size encoded which we want to ignore for this special case.
    private var p1 = UInt8("S".utf8.first!)
    private var p2 = UInt8("P".utf8.first!)
    private var p3 = UInt8("S".utf8.first!)
}
