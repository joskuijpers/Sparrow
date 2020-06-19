//
//  TextureLoader.swift
//  SparrowEngine
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
    private let mtkLoader: MTKTextureLoader
//    private var cache: [String : Texture] = [:]
//
//    var allocatedSize: Int {
//        return cache.reduce(0) { $0 + $1.value.mtlTexture.allocatedSize }
//    }
//
    /// Loading options
    public enum Option {
        /// A key used to specify whether the texture loader should allocate memory for mipmaps in the texture.
        case allocateMipmaps(Bool)
        
        /// A key used to specify whether the texture loader should generate mipmaps for the texture.
        case generateMipmaps(Bool)

        /// A key used to specify the CPU cache mode for the texture.
        ///
        /// If this key is not specified, the default value is the value associated with `MTLCPUCacheMode.defaultCache`.
        case textureCPUCacheMode(MTLCPUCacheMode)
        
        /// A key used to specify the storage mode for the texture.
        case textureStorageMode(MTLStorageMode)
        
        /// A key used to specify the intended usage of the texture.
        case textureUsage(MTLTextureUsage)

        /// A key used to specify when to flip the pixel coordinates of the texture.
        ///
        /// If you omit this option, the texture loader doesn’t flip loaded textures.
        case origin(MTKTextureLoader.Origin)
        
        /// A key used to specify how cube texture data is arranged in the source image.
        ///
        /// If this option is omitted, the texture loader does not create a cube texture.
        case cubeLayout(MTKTextureLoader.CubeLayout)

        /// A key used to specify whether the texture data is stored as sRGB image data.
        ///
        /// If the value is `false`, the image data is treated as linear pixel data. If the value is `true`, the image
        /// data is treated as sRGB pixel data. If this key is not specified and the image being loaded has been
        /// gamma-corrected, the image data uses the specified sRGB information.
        case SRGB(Bool)
    }
    
    /// Initialize a new texture loader.
    public init(device: MTLDevice) {
        self.mtkLoader = MTKTextureLoader(device: device)
    }

    /// Load a texture with given image name. This can be a path or an asset name.
    public func load(from url: URL, options: [Option] = []) throws -> Texture {
        let url = optimizedFormat(url)
    
        // Get from cache
//        if let texture = cache[url.absoluteString] {
//            return texture
//        }

        let data = try Data(contentsOf: url)
        let texture = try mtkLoader.newTexture(data: data, options: options.mtkOptions)
        
        print("Loaded \(url.lastPathComponent)... (texture.allocatedSize / 1024) KiB")
        
        return Texture(name: ResourceManager.resourcePath(for: url), mtlTexture: texture)
    }
    
    /// Try to load DDS if available
    private func optimizedFormat(_ url: URL) -> URL {
        if url.pathExtension == "png" {
            let ddsUrl = url.deletingPathExtension().appendingPathExtension("dds")
            if FileManager.default.fileExists(atPath: ddsUrl.path) {
                return ddsUrl
            }
        }
        return url
    }

//
//    /// Synchronously loads image data and creates a new Metal texture from a given URL.
//    func newTexture(URL: URL, options: [MTKTextureLoader.Option : Any]?) -> MTLTexture
//
//    /// Asynchronously loads image data and creates a new Metal texture from a given URL.
//    func newTexture(URL: URL, options: [MTKTextureLoader.Option : Any]?, completionHandler: MTKTextureLoader.Callback)
//
//    /// Synchronously loads image data and creates new Metal textures from the specified list of URLs.
//    func newTextures(URLs: [URL], options: [MTKTextureLoader.Option : Any]?, error: NSErrorPointer) -> [MTLTexture]
//
//    /// Asynchronously loads image data and creates new Metal textures from the specified list of URLs.
//    func newTextures(URLs: [URL], options: [MTKTextureLoader.Option : Any]?, completionHandler: MTKTextureLoader.ArrayCallback)
}

extension Array where Element == TextureLoader.Option {
    var mtkOptions: [MTKTextureLoader.Option:Any] {
        var output: [MTKTextureLoader.Option: Any] = [:]

        for option in self {
            switch option {
            case .allocateMipmaps(let yes):
                output[.allocateMipmaps] = yes
            case .generateMipmaps(let yes):
                output[.generateMipmaps] = yes
            case .textureCPUCacheMode(let mode):
                output[.textureCPUCacheMode] = mode
            case .textureUsage(let usage):
                output[.textureUsage] = usage
            case .textureStorageMode(let mode):
                output[.textureStorageMode] = mode
            case .origin(let origin):
                output[.origin] = origin
            case .cubeLayout(let layout):
                output[.cubeLayout] = layout
            case .SRGB(let yes):
                output[.SRGB] = yes
            }
        }
        
        if output[.origin] == nil {
            output[.origin] = MTKTextureLoader.Origin.bottomLeft
        }
        if output[.SRGB] == nil {
           output[.SRGB] = false
        }
        if output[.generateMipmaps] == nil {
           output[.generateMipmaps] = true
        }
        
        return output
    }
}

/// A texture.
public class Texture {
    public let name: String
    public let mtlTexture: MTLTexture

    fileprivate init(name: String, mtlTexture: MTLTexture) {
        self.name = name
        self.mtlTexture = mtlTexture
    }
}
