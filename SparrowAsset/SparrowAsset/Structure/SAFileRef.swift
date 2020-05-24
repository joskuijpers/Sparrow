//
//  SAFile.swift
//  SparrowAsset
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

public final class SAFileRef {
    public let url: URL
    public let asset: SAAsset
    
    public init(url: URL, asset: SAAsset) {
        self.url = url
        self.asset = asset
    }
}
