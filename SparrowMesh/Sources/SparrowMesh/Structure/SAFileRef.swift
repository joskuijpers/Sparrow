//
//  SAFile.swift
//  SparrowAsset
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// A reference holder for an asset.
///
/// Also contains the path of the asset for resolving relative paths.
public final class SAFileRef {
    /// Path of the asset that is loaded.
    public let url: URL
    
    /// The loaded asset.
    public let asset: SAAsset
    
    /// Create a new ref.
    public init(url: URL, asset: SAAsset) {
        self.url = url
        self.asset = asset
    }
}
