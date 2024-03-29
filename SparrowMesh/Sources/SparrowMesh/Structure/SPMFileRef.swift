//
//  SPMFileRef.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// A reference holder for an asset.
///
/// Also contains the path of the asset for resolving relative paths.
public final class SPMFileRef {
    /// Path of the asset that is loaded.
    public let url: URL
    
    /// The loaded mesh file.
    public let file: SPMFile
    
    /// Create a new ref.
    public init(url: URL, file: SPMFile) {
        self.url = url
        self.file = file
    }
}
