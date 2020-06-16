//
//  TextureLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal
import Foundation
import CoreGraphics
import Cocoa
import CSparrowEngine

/// Texture loader that ensures any texture is only loaded once
///
/// Note that this uses MTKTextureLoader internally, which also caches but seems to be much slower as
/// it does not assume the same options for all.
public class TextureLoader {
    private let device: MTLDevice
//    private var cache: [String : Texture] = [:]
    
//    var allocatedSize: Int {
//        return cache.reduce(0) { $0 + $1.value.mtlTexture.allocatedSize }
//    }
    
    /// Loading options
    enum Option {
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
        case origin(Origin)
        
        /// A key used to specify how cube texture data is arranged in the source image.
        ///
        /// If this option is omitted, the texture loader does not create a cube texture.
        case cubeLayout(CubeLayout)

        /// A key used to specify whether the texture data is stored as sRGB image data.
        ///
        /// If the value is `false`, the image data is treated as linear pixel data. If the value is `true`, the image
        /// data is treated as sRGB pixel data. If this key is not specified and the image being loaded has been
        /// gamma-corrected, the image data uses the specified sRGB information.
        case SRGB(Bool)
    }
    
    /// Options for specifying when to flip the pixel coordinates of the texture.
    enum Origin {
        /// An option for specifying images that should be flipped only to put their origin in the top-left corner.
        case topLeft
        
        /// An option for specifying images that should be flipped only to put their origin in the bottom-left corner.
        case bottomLeft
        
        /// An option that specifies that images should always be flipped.
        case flippedVertically
    }
    
    /// Options for specifying how cube texture data is arranged in the source image.
    enum CubeLayout {
        /// Specifies that the source 2D image is a vertical arrangement of six cube faces.
        case vertical
    }
    
    /// Texture container format
    enum TextureContainerFormat {
        /// Not compressed for hardware (png)
        case notHardwareCompressed
        /// ASTC format.
        case astc
        /// KTX format.
        case ktx
        
        /// No known format
        case unknown
    }
    
    /// Errors returned by the texture loader.
    public enum Error: Swift.Error {
        /// Format not supported
        case unsupportedFormat
        
        /// Failed to create GPU texture
        case uploadFailed
        
        /// There was no data to construct a texture from
        case noImages
        
        /// Could not acquire storage for the texture on the GPU.
        case noTextureStorage
    }
    
    private static let codecs: [TextureContainerFormat:TextureCodec.Type] = [
        .notHardwareCompressed: UncompressedTextureCodec.self
    ]
    
    /// Initialize a new texture loader.
    public init(device: MTLDevice) {
        self.device = device
    }

    /// Load a texture with given image name. This can be a path or an asset name.
    public func load(from url: URL) throws -> Texture {
        // Get from cache
//        if let texture = cache[url.absoluteString] {
//            return texture
//        }
        
        // Hardcode: try to find a better format than PNG
        var url = url
        if url.pathExtension == "png" {
            let astcPath = url.deletingPathExtension().appendingPathExtension("astc")
            if FileManager.default.fileExists(atPath: astcPath.path) {
                url = astcPath
            }
        }
        
        print("Loading \(url.lastPathComponent)...")
        
        let data = try Data(contentsOf: url)
        
        let format = findContainerFormat(for: data)
        if format == .unknown {
            throw Error.unsupportedFormat
        }
        
        print("Found format \(format)")
        
        let descriptor = try load(from: data, format: format)
        let texture = try buildTexture(with: descriptor, name: AssetLoader.shortestName(for: url))
        

//        let options: [MTKTextureLoader.Option: Any] = [
//            .origin: MTKTextureLoader.Origin.bottomLeft,
//            .SRGB: false,
//            .generateMipmaps: true,
//        ]

        return texture
    }
    
    /// Try to find the container that is used for given data.
    private func findContainerFormat(for data: Data) -> TextureContainerFormat {
        for (format, codec) in Self.codecs {
            if codec.isContained(in: data) {
                return format
            }
        }
        
        return .unknown
    }
    
    /// Load a texture from given data and format
    ///
    /// Forwards actual loading to the codec.
    private func load(from data: Data, format: TextureContainerFormat) throws -> TextureDescriptor {
        guard let codec = Self.codecs[format] else {
            throw Error.unsupportedFormat
        }
        
        return try codec.init().load(from: data)
    }

    /// Get whether we can generate mipmaps from a texture with given format.
    private func pixelFormatIsColorRenderable(_ pixelFormat: MTLPixelFormat) -> Bool {
//        BOOL isCompressedFormat = (pixelFormat >= MTLPixelFormatASTC_4x4_sRGB && pixelFormat <= MTLPixelFormatASTC_12x12_LDR) ||
//                                  (pixelFormat >= MTLPixelFormatPVRTC_RGB_2BPP && pixelFormat <= MTLPixelFormatPVRTC_RGBA_4BPP_sRGB) ||
//                                  (pixelFormat >= MTLPixelFormatEAC_R11Unorm && pixelFormat <= MTLPixelFormatETC2_RGB8A1_sRGB);
        let is422Format = pixelFormat == .gbgr422 || pixelFormat == .bgrg422

        return /*!isCompressedFormat &&*/ !is422Format && pixelFormat != .invalid
    }
    
    /// Build a texture using a descriptor.
    private func buildTexture(with descriptor: TextureDescriptor, name: String) throws -> Texture {
        guard descriptor.levels.count > 0 else {
            throw Error.noImages
        }

        let mipsLoaded = descriptor.levels.count > 1
        let canGenerateMips = pixelFormatIsColorRenderable(descriptor.pixelFormat)
        
        var generateMipmaps = true
        if mipsLoaded || !canGenerateMips {
            generateMipmaps = false
        }
        
        let needMipStorage = generateMipmaps || mipsLoaded
        print("Has mips \(mipsLoaded) will generate mips \(generateMipmaps)")
        
        let mtlDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: descriptor.pixelFormat,
                                                                     width: descriptor.width,
                                                                     height: descriptor.height,
                                                                     mipmapped: needMipStorage)
//        mtlDescriptor.resourceOptions = .cpuCacheModeWriteCombined
//        mtlDescriptor.mipmapLevelCount =
//        mtlDescriptor.usage = .shaderRead
//        mtlDescriptor.cpuCacheMode = .defaultCache
        
        guard let texture = device.makeTexture(descriptor: mtlDescriptor) else {
            throw Error.noTextureStorage
        }
        texture.label = name
        
        var levelWidth = descriptor.width
        var levelHeight = descriptor.height
        var levelBytesPerRow = descriptor.bytesPerRow
        for (index, level) in descriptor.levels.enumerated() {
            let region = MTLRegionMake2D(0, 0, levelWidth, levelHeight)
            level.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in
                texture.replace(region: region,
                                mipmapLevel: index,
                                withBytes: ptr.baseAddress!,
                                bytesPerRow: levelBytesPerRow)
            }
            
            levelWidth = max(descriptor.width / 2, 1)
            levelHeight = max(descriptor.height / 2, 1)
            levelBytesPerRow = max(descriptor.bytesPerRow / 2, 16)
        }
        
        if generateMipmaps {
            print("Generate mipmaps!")
//            generateMipmaps(texture: texture, commandQueue: )
        }
        
        return Texture(name: name, mtlTexture: texture)
    }
    
    /// Generate mipmaps on the GPU.
    private func generateMipmaps(texture: MTLTexture, commandQueue: MTLCommandQueue) {
        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeBlitCommandEncoder()
        
        encoder?.generateMipmaps(for: texture)
        
        encoder?.endEncoding()
        commandBuffer?.commit()
        
        // Blocking!
        commandBuffer?.waitUntilCompleted()
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

/// A texture.
public class Texture {
    public let name: String
    public let mtlTexture: MTLTexture

    init(name: String, mtlTexture: MTLTexture) {
        self.name = name
        self.mtlTexture = mtlTexture
    }
}

/// Texture information for building a GPU representation
struct TextureDescriptor {
    let pixelFormat: MTLPixelFormat
    let width: Int
    let height: Int
    let mipmapCount: Int
    let bytesPerRow: Int
    let levels: [Data]
}
