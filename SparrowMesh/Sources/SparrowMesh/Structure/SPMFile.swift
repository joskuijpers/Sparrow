//
//  SPMFile.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// Sparrow Asset file format.
public struct SPMFile: BinaryCodable {
    /// File header with indicator, version, generator, and origin.
    let header: SPMFileHeader
    
    /// File checksum.
    ///
    /// Composed of the sizes of the content lists.
    private var checksum: UInt = 0
    
    /// Mesh.
    public var mesh: SPMMesh? = nil
    
    /// List of materials.
    public var materials: [SPMMaterial] = []
    
    /// List of textures.
    public var textures: [SPMTexture] = []
    
    /// List of buffers.
    public var buffers: [SPMBuffer] = []
    
    /// List of buffer views.
    public var bufferViews: [SPMBufferView] = []
    
    /// Create an empty asset with a filled header.
    public init(generator: String, origin: String?) {
        self.header = SPMFileHeader(generator: generator, origin: origin)
    }
}

extension SPMFile {
    /// Update the checksum to match the content.
    public mutating func updateChecksum() {
        checksum = generateChecksum()
    }
    
    /// Generate the checksum from the content.
    private func generateChecksum() -> UInt {
        var checksum: UInt = 0
        
        checksum = checksum * 11 + UInt(materials.count)
        checksum = checksum * 11 + UInt(mesh == nil ? 0 : 1)
        checksum = checksum * 11 + UInt(textures.count)
        checksum = checksum * 11 + UInt(buffers.count)
        checksum = checksum * 11 + UInt(bufferViews.count)
        
        return checksum
    }
    
    /// Get whether the checksum is valid for the content.
    public func verifyChecksum() -> Bool {
        return checksum == generateChecksum()
    }
}
