//
//  SPMFileHeader.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// Sparrow Asset file header.
struct SPMFileHeader: BinaryCodable {
    /// Indicator of the SparrowAsset file: a prefix.
    private(set) var indicator = SPMFileHeaderIndicator() // Must be a var so codable can override it
    
    /// Version of the file format
    private(set) var version: SPMFileVersion = .version1
    
    /// The generator used to generate the file.
    let generator: String
    
    /// The origin of the data used to generate the file. Useful for re-generation
    let origin: String
    
    /// The version of the asset file format
    enum SPMFileVersion: UInt8, BinaryCodable {
        case version1 = 1
    }
    
    /// Create a header.
    init(generator: String, origin: String?) {
        self.generator = generator
        self.origin = origin ?? ""
    }
}

/// File header indicator: 3 bytes 'SPM '
struct SPMFileHeaderIndicator: BinaryCodable {
    // A string has a size encoded which we want to ignore for this special case.
    private var p1 = UInt8("S".utf8.first!)
    private var p2 = UInt8("P".utf8.first!)
    private var p3 = UInt8("M".utf8.first!)
}
