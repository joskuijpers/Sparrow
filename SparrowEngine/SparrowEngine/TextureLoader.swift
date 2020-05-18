//
//  TextureLoader.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import ModelIO
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
    func load(imageName: String) -> Texture? {
        // Get from cache
        if let texture = cache[imageName] {
            return texture
        }
        
        // Get new
        let options: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: true,
        ]
        
        if let mtlTexture = try? loadMtlTexture(imageName: imageName, textureLoaderOptions: options) {
            let texture = Texture(imageName: imageName, mtlTexture: mtlTexture)
            cache[imageName] = texture
            
            print("[texture] Loaded \(texture.imageName) (\(Float(texture.mtlTexture.allocatedSize) / 1024 / 1024) MiB)")

            return texture
        }
        
        return nil
    }
    
    /**
     Load the MTL internal texture
     */
    private func loadMtlTexture(imageName: String, textureLoaderOptions: [MTKTextureLoader.Option: Any]) throws -> MTLTexture? {
        let fileExtension = URL(fileURLWithPath: imageName).pathExtension.isEmpty ? "png" : nil
        guard let url = Bundle.main.url(forResource: imageName, withExtension: fileExtension) else {
//            print("Loading \(imageName) from bundle")
            return try mtkTextureLoader.newTexture(name: imageName, scaleFactor: 1.0, bundle: Bundle.main, options: nil)
        }

//        print("Loading \(imageName) from path")
        return try mtkTextureLoader.newTexture(URL: url, options: textureLoaderOptions)
    }
    
    /**
     Unload given texture from the cache. Data will only unload once the texture is released.
     */
    func unload(_ texture: Texture) {
        cache.removeValue(forKey: texture.imageName)
    }
    
    /**
     Reload the given texture, returning a new one. Also flushes cache for this item.
     */
    func reload(_ texture: Texture) -> Texture? {
        cache.removeValue(forKey: texture.imageName)
        
        return load(imageName: texture.imageName)
    }
}

/// A texture.
struct Texture {
    let imageName: String
    let mtlTexture: MTLTexture
}
