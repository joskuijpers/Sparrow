//
//  AssetLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// TODO: REMOVE/REFACTOR INTO SOMETHING TO HANDLE res:// PATHS.
public struct AssetLoader {
    
    private init() {}
    
    public static func resourceUrl() -> URL {
        return Bundle.main.resourceURL!
            .appendingPathComponent("Assets")
    }
    
    /// Path for given asset. If asset does not exist, returns nil
    public static func url(forAsset name: String) -> URL {
        return resourceUrl().appendingPathComponent(name).absoluteURL
    }
    
    public static func shortestName(for url: URL) -> String {
        let rp = resourceUrl().path
        if url.path.hasPrefix(rp) {
            return String(url.path.dropFirst(rp.count + 1)) // +1 for the /
        } else {
            return url.path
        }
    }
}
