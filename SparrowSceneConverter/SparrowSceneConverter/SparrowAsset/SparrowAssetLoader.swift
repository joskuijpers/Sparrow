//
//  SparrowAssetLoader.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

class SparrowAssetLoader {
    
    enum Error: Swift.Error {
        /// The file is not a valid asset
        case invalidAssetFormat
        
        /// The version of the asset does not match the version of the code.
        case invalidAssetVersion
    }
    
    /**
     Load an asset from given URL.
     */
    static func load(from url: URL) throws -> SAAsset {
        
        
        let header = SAFileHeader(version: .version1, generator: "test", origin: "test")
        return SAAsset(header: header)
    }
}
