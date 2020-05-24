//
//  TextureLoader.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
 Texture loader that ensures any texture is only loaded once
 
 Note that this uses MTKTextureLoader internally, which also caches but seems to be much slower as
 it does not assume the same options for all.
 */
class TextureLoader {
    private var cache: [String : Texture] = [:]
    private let mtkTextureLoader: MTKTextureLoader
    
    var allocatedSize: Int {
        var total = 0
        
        for (_, texture) in cache {
            total += texture.mtlTexture.allocatedSize
        }
        
        return total
    }
    
    /// Initialize a new texture loader.
    init() {
        mtkTextureLoader = MTKTextureLoader(device: Renderer.device)
    }
    
    /**
     Flush the cache by removing all cached textures. Textures keep alive
     */
    func flush() {
        cache.removeAll(keepingCapacity: true)
    }
    
    /**
     Load a texture with given image name. This can be a path or an asset name.
     */
    func load(from url: URL) throws -> Texture {
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
        print("FROM \(url) to \(imageName)")
        
        let mtlTexture = try mtkTextureLoader.newTexture(URL: url, options: options)
        let texture = Texture(imageName: imageName, mtlTexture: mtlTexture)
        
        cache[url.absoluteString] = texture
        
        print("[texture] Loaded \(texture.imageName) (\(Float(mtlTexture.allocatedSize) / 1024 / 1024) MiB)")

        return texture
    }
    
    /**
     Unload given texture from the cache. Data will only unload once the texture is released.
     */
    func unload(_ texture: Texture) {
        cache.removeValue(forKey: texture.imageName)
    }
}

/// A texture.
struct Texture {
    let imageName: String
    let mtlTexture: MTLTexture
}
