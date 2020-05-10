//
//  SAAsset.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

/// Sparrow Asset file format.
struct SAAsset: BinaryCodable {
    /// File header with indicator, version, generator, and origin.
    let header: SAFileHeader
    
    var materials: [SAMaterial] = []
    var nodes: [SANode] = []
    var meshes: [SAMesh] = []
    var textures: [SATexture] = []
    var scenes: [SAScene] = []
    var buffers: [SABuffer] = []
    var bufferViews: [SABufferView] = []
    var lights: [SALight] = []
    
    var checksum: UInt = 0
    
    /// Update the checksum to match the content.
    mutating func updateChecksum() {
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
    func verifyChecksum() -> Bool {
        return checksum == generateChecksum()
    }
}
