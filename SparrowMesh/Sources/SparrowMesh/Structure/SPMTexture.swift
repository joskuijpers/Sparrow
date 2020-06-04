//
//  SPMTexture.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// A texture representation.
///
/// Links to a texture on disk.
public struct SPMTexture: BinaryCodable {
    
    /// Relative path to the texture from the path of the asset.
    public let relativePath: String
    
    /// Create a new texture representation.
    public init(relativePath: String) {
        self.relativePath = relativePath
    }
}
