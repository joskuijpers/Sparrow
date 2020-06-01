//
//  TextureLoader.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

/// Texture loader that ensures any texture is only loaded once
///
/// Note that this uses MTKTextureLoader internally, which also caches but seems to be much slower as
/// it does not assume the same options for all.
public class TextureLoader {
    private var cache: [String : Texture] = [:]
    private let mtkTextureLoader: MTKTextureLoader
    
    var allocatedSize: Int {
        return cache.reduce(0) { $0 + $1.value.mtlTexture.allocatedSize }
    }
    
    /// Initialize a new texture loader.
    public init(device: MTLDevice) {
        mtkTextureLoader = MTKTextureLoader(device: device)
    }
    
    /// Flush the cache by removing all cached textures. Textures keep alive
    func flush() {
        cache.removeAll(keepingCapacity: true)
    }
    
    /// Load a texture with given image name. This can be a path or an asset name.
    public func load(from url: URL) throws -> Texture {
        // Get from cache
        if let texture = cache[url.absoluteString] {
            return texture
        }
        
        // Get new
        let options: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: true,
        ]
        
        let imageName = AssetLoader.shortestName(for: url)
        
        let mtlTexture = try mtkTextureLoader.newTexture(URL: url, options: options)
        let texture = Texture(imageName: imageName, mtlTexture: mtlTexture)
        
        cache[url.absoluteString] = texture
        
        print("[texture] Loaded \(texture.imageName) (\(Float(mtlTexture.allocatedSize) / 1024 / 1024) MiB)")

        return texture
    }
    
    /// Unload given texture from the cache. Data will only unload once the texture is released.
    func unload(_ texture: Texture) {
        cache.removeValue(forKey: texture.imageName)
    }
}

/// A texture.
public struct Texture {
    public let imageName: String
    public let mtlTexture: MTLTexture
}
