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
    private let indicator = SAFileHeaderIndicator()
    
    /// Version of the file format
    var version: SAFileVersion
    
    /// The generator used to generate the file.
    var generator: String
    
    /// The origin of the data used to generate the file. Useful for re-generation
    var origin: String
    
    /// The version of the asset file format
    enum SAFileVersion: UInt8, BinaryCodable {
        case version1 = 1
    }
}

/// File header indicator: 3 bytes 'SA '
struct SAFileHeaderIndicator: BinaryCodable {
    // A string has a size encoded which we want to ignore for this special case.
    
    private let p1 = UInt8("S".utf8.first!)
    private let p2 = UInt8("A".utf8.first!)
    private let p3 = UInt8(" ".utf8.first!)
}
