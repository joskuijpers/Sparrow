//
//  SAAsset.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// Sparrow Asset file format.
public struct SAAsset: BinaryCodable {
    /// File header with indicator, version, generator, and origin.
    let header: SAFileHeader
    
    /**
     File checksum.
     
     Composed of the sizes of the content lists.
     */
    private var checksum: UInt = 0
    
    public var materials: [SAMaterial] = []
    public var nodes: [SANode] = []
    public var meshes: [SAMesh] = []
    public var textures: [SATexture] = []
    public var scenes: [SAScene] = []
    public var buffers: [SABuffer] = []
    public var bufferViews: [SABufferView] = []
    public var lights: [SALight] = []
    
    public init(header: SAFileHeader) {
        self.header = header
    }
    
    public init(generator: String, origin: String?) {
        self.header = SAFileHeader(generator: generator, origin: origin)
    }
}

extension SAAsset {
    /// Update the checksum to match the content.
    public mutating func updateChecksum() {
        checksum = generateChecksum()
    }
    
    /// Generate the checksum from the content.
    private func generateChecksum() -> UInt {
        var checksum: UInt = 0
        
        checksum = checksum * 11 + UInt(materials.count)
        checksum = checksum * 11 + UInt(nodes.count + 1)
        checksum = checksum * 11 + UInt(meshes.count)
        checksum = checksum * 11 + UInt(textures.count)
        checksum = checksum * 11 + UInt(scenes.count)
        checksum = checksum * 11 + UInt(buffers.count)
        checksum = checksum * 11 + UInt(bufferViews.count)
        checksum = checksum * 11 + UInt(lights.count)
        
        return checksum
    }
    
    /// Get whether the checksum is valid for the content.
    public func verifyChecksum() -> Bool {
        return checksum == generateChecksum()
    }
}
