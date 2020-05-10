//
//  SAFileHeader.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

/// Sparrow Asset file header.
struct SAFileHeader: BinaryCodable {
    /// Indicator of the SparrowAsset file: a prefix.
    let indicator: SAFileHeaderIndicator
    
    /// Version of the file format
    let version: SAFileVersion
    
    /// The generator used to generate the file.
    var generator: String
    
    /// The origin of the data used to generate the file. Useful for re-generation
    var origin: String
    
    /// The version of the asset file format
    enum SAFileVersion: UInt8, BinaryCodable {
        case version1 = 1
    }
    
    init(generator: String, origin: String?) {
        self.indicator = SAFileHeaderIndicator()
        self.version = .version1
        self.generator = generator
        self.origin = origin ?? ""
    }
}

/// File header indicator: 3 bytes 'SA '
struct SAFileHeaderIndicator: BinaryCodable {
    // A string has a size encoded which we want to ignore for this special case.
    private let p1: UInt8
    private let p2: UInt8
    private let p3: UInt8
    
    init() {
        // Note: cannot use default values as they are not read!
        p1 = UInt8("S".utf8.first!)
        p2 = UInt8("A".utf8.first!)
        p3 = UInt8(" ".utf8.first!)
    }
}
