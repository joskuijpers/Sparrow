//
//  AssetLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct AssetLoader {
    
    private init() {}
    
    static func resourceUrl() -> URL {
        return Bundle.main.resourceURL!
            .appendingPathComponent("Assets")
    }
    
    /// Path for given asset. If asset does not exist, returns nil
    static func url(forAsset name: String) -> URL {
        return resourceUrl().appendingPathComponent(name).absoluteURL
    }
    
    static func shortestName(for url: URL) -> String {
        let rp = resourceUrl().path
        if url.path.hasPrefix(rp) {
            return String(url.path.dropFirst(rp.count + 1)) // +1 for the /
        } else {
            return url.path
        }
    }
}
