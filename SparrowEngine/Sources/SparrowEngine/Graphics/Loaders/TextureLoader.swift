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
//        var url = url
//        if url.pathExtension == "png" {
//            let astcPath = url.deletingPathExtension().appendingPathExtension("astc")
//            if FileManager.default.fileExists(atPath: astcPath.path) {
//                url = astcPath
//            }
//        }
        
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
//
//        let imageName = AssetLoader.shortestName(for: url)

        return texture
    }
    
    /// Try to find the container that is used for given data.
    private func findContainerFormat(for data: Data) -> TextureContainerFormat {
        if UncompressedTextureCodec.isContained(in: data) {
            return .notHardwareCompressed
        } else if ASTCTextureCodec.isContained(in: data) {
            return .astc
        } else if KTXTextureCodec.isContained(in: data) {
            return .ktx
        }
        
        return .unknown
    }
    
    /// Load a texture from given data and format
    ///
    /// Forwards actual loading to the codec.
    private func load(from data: Data, format: TextureContainerFormat) throws -> TextureDescriptor {
        switch format {
        case .notHardwareCompressed:
            return try UncompressedTextureCodec().load(from: data)
        case .astc:
            return try ASTCTextureCodec().load(from: data)
        case .ktx:
            return try KTXTextureCodec().load(from: data)
        case .unknown:
            throw Error.unsupportedFormat
        }
    }

    private func pixelFormatIsColorRenderable(_ pixelFormat: MTLPixelFormat) -> Bool {
//        BOOL isCompressedFormat = (pixelFormat >= MTLPixelFormatASTC_4x4_sRGB && pixelFormat <= MTLPixelFormatASTC_12x12_LDR) ||
//                                  (pixelFormat >= MTLPixelFormatPVRTC_RGB_2BPP && pixelFormat <= MTLPixelFormatPVRTC_RGBA_4BPP_sRGB) ||
//                                  (pixelFormat >= MTLPixelFormatEAC_R11Unorm && pixelFormat <= MTLPixelFormatETC2_RGB8A1_sRGB);
//        BOOL is422Format = (pixelFormat == MTLPixelFormatGBGR422 || pixelFormat == MTLPixelFormatBGRG422);
//
//        return !isCompressedFormat && !is422Format && !(pixelFormat == MTLPixelFormatInvalid);
        return false
    }
    
    private func buildTexture(with descriptor: TextureDescriptor, name: String) throws -> Texture {
        guard descriptor.levels.count > 0 else {
            throw Error.noImages
        }
        
        print("Make a new texture for \(name)!")
        
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
        print("L \(mtlDescriptor.width) \(mtlDescriptor.height) \(mtlDescriptor.depth) ")
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

// A decoder for a texture format.
protocol TextureCodec {
    /// Get whether the codec is used inside given data
    static func isContained(in data: Data) -> Bool
    
    /// Load a texture.
    func load(from data: Data) throws -> TextureDescriptor
}

//const uint32_t MBEPVRLegacyMagic = 0x21525650;
//const uint32_t MBEPVRv3Magic = 0x03525650;

struct ASTCTextureCodec: TextureCodec {
    static let magic: UInt32 = 0x5CA1AB13
    
    static func isContained(in data: Data) -> Bool {
        if data.count < MemoryLayout<ASTCHeader>.size {
            return false
        }
        
        let header = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> ASTCHeader in
            ptr.load(as: ASTCHeader.self)
        }
        
        let fileMagic = CFSwapInt32LittleToHost(header.magic)
        return fileMagic == Self.magic
    }
    
    func load(from data: Data) throws -> TextureDescriptor {
        throw TextureLoader.Error.unsupportedFormat
    }
}

struct KTXTextureCodec: TextureCodec {
    static let magic: UInt32 = 0xAB4B5458
    
    static func isContained(in data: Data) -> Bool {
        if data.count < MemoryLayout<KTXHeader>.size {
            return false
        }
        
        let header = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> KTXHeader in
            ptr.load(as: KTXHeader.self)
        }

        return header.identifier.1 == UInt8("K".utf8.first!)
            && header.identifier.2 == UInt8("T".utf8.first!)
            && header.identifier.3 == UInt8("X".utf8.first!)
            && header.identifier.4 == UInt8(" ".utf8.first!)
            && header.identifier.5 == UInt8("1".utf8.first!)
            && header.identifier.6 == UInt8("1".utf8.first!)
    }
    
    func load(from data: Data) throws -> TextureDescriptor {
        throw TextureLoader.Error.unsupportedFormat
    }
}

/// Codec for loading system supported formats such as PNG and TIFF.
///
/// Normalizes the data to a known pixel format.
struct UncompressedTextureCodec: TextureCodec {

    enum Error: Swift.Error {
        case readingFailed
        case allocationFailed
        case normalizationFailed
    }
    
    static func isContained(in data: Data) -> Bool {
        if data.count < 1 {
            return false
        }
        
        let firstByte = data.first!
        switch firstByte {
        case 0xff, 0x89, 0x47, 0x49, 0x4d: // JPEG, PNG, GIF, TIFF, TIFF
            return true
        default:
            return false
        }
    }
    
    func load(from data: Data) throws -> TextureDescriptor {
        guard let image = NSImage(data: data) else {
            throw Error.readingFailed
        }

        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        print("RECT \(imageRect)")
        guard let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
            throw Error.readingFailed
        }
        
        // Normalize the content
        let dataLength = imageRef.width * imageRef.height * 4
        guard let buffer = calloc(dataLength, MemoryLayout<UInt8>.size) else {
            throw Error.allocationFailed
        }
        memset(buffer, 255, dataLength)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = imageRef.width * bytesPerPixel
        let bitsPerComponent = 8
        
        let context = CGContext(data: buffer,
                                width: imageRef.width,
                                height: imageRef.height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        guard context != nil else {
            throw Error.normalizationFailed
        }
        context!.draw(imageRef, in: imageRect)

        let level = Data(bytesNoCopy: buffer, count: dataLength, deallocator: .free)
        return TextureDescriptor(pixelFormat: .rgba8Unorm,
                                 width: Int(imageRect.width),
                                 height: Int(imageRect.height),
                                 mipmapCount: 1,
                                 bytesPerRow: bytesPerRow,
                                 levels: [level])
    }
}

/*
 
 ASTC texture loading
 https://metalbyexample.com/compressed-textures/

 typedef NS_ENUM(NSInteger, MBEKTXInternalFormat)
 {
     MBEKTXInternalFormatASTC_4x4   = 37808,
     MBEKTXInternalFormatASTC_5x4   = 37809,
     MBEKTXInternalFormatASTC_5x5   = 37810,
     MBEKTXInternalFormatASTC_6x5   = 37811,
     MBEKTXInternalFormatASTC_6x6   = 37812,
     MBEKTXInternalFormatASTC_8x5   = 37813,
     MBEKTXInternalFormatASTC_8x6   = 37814,
     MBEKTXInternalFormatASTC_8x8   = 37815,
     MBEKTXInternalFormatASTC_10x5  = 37816,
     MBEKTXInternalFormatASTC_10x6  = 37817,
     MBEKTXInternalFormatASTC_10x8  = 37818,
     MBEKTXInternalFormatASTC_10x10 = 37819,
     MBEKTXInternalFormatASTC_12x10 = 37820,
     MBEKTXInternalFormatASTC_12x12 = 37821,

     MBEKTXInternalFormatASTC_4x4_sRGB   = 37840,
     MBEKTXInternalFormatASTC_5x4_sRGB   = 37841,
     MBEKTXInternalFormatASTC_5x5_sRGB   = 37842,
     MBEKTXInternalFormatASTC_6x5_sRGB   = 37843,
     MBEKTXInternalFormatASTC_6x6_sRGB   = 37844,
     MBEKTXInternalFormatASTC_8x5_sRGB   = 37845,
     MBEKTXInternalFormatASTC_8x6_sRGB   = 37846,
     MBEKTXInternalFormatASTC_8x8_sRGB   = 37847,
     MBEKTXInternalFormatASTC_10x5_sRGB  = 37848,
     MBEKTXInternalFormatASTC_10x6_sRGB  = 37849,
     MBEKTXInternalFormatASTC_10x8_sRGB  = 37850,
     MBEKTXInternalFormatASTC_10x10_sRGB = 37851,
     MBEKTXInternalFormatASTC_12x10_sRGB = 37852,
     MBEKTXInternalFormatASTC_12x12_sRGB = 37853,
 };
 
 
 - (MTLPixelFormat)pixelFormatForASTCBlockWidth:(uint32_t)blockWidth
                                    blockHeight:(uint32_t)blockHeight
                                colorSpaceIsLDR:(BOOL)colorSpaceIsLDR
 {
     MTLPixelFormat pixelFormat = MTLPixelFormatInvalid;

     if (blockWidth == 4)
     {
         if (blockHeight == 4)
         {
             pixelFormat = MTLPixelFormatASTC_4x4_LDR;
         }
     }
     else if (blockWidth == 5)
     {
         if( blockHeight == 4)
         {
             pixelFormat = MTLPixelFormatASTC_5x4_LDR;
         }
         else if (blockHeight == 5)
         {
             pixelFormat = MTLPixelFormatASTC_5x5_LDR;
         }
     }
     else if (blockWidth == 6)
     {
         if( blockHeight == 5)
         {
             pixelFormat = MTLPixelFormatASTC_6x5_LDR;
         }
         else if (blockHeight == 6)
         {
             pixelFormat = MTLPixelFormatASTC_6x6_LDR;
         }
     }
     else if (blockWidth == 8)
     {
         if( blockHeight == 5)
         {
             pixelFormat = MTLPixelFormatASTC_8x5_LDR;
         }
         else if (blockHeight == 6)
         {
             pixelFormat = MTLPixelFormatASTC_8x6_LDR;
         }
         else if (blockHeight == 8)
         {
             pixelFormat = MTLPixelFormatASTC_8x8_LDR;
         }
     }
     else if (blockWidth == 10)
     {
         if( blockHeight == 5)
         {
             pixelFormat = MTLPixelFormatASTC_10x5_LDR;
         }
         else if (blockHeight == 6)
         {
             pixelFormat = MTLPixelFormatASTC_10x6_LDR;
         }
         else if (blockHeight == 8)
         {
             pixelFormat = MTLPixelFormatASTC_10x8_LDR;
         }
         else if (blockHeight == 10)
         {
             pixelFormat = MTLPixelFormatASTC_10x10_LDR;
         }
     }
     else if (blockWidth == 12)
     {
         if (blockHeight == 10)
         {
             pixelFormat = MTLPixelFormatASTC_12x10_LDR;
         }
         else if (blockHeight == 12)
         {
             pixelFormat = MTLPixelFormatASTC_12x12_LDR;
         }
     }

     // Adjust pixel format if we're actually sRGB instead of LDR
     if (!colorSpaceIsLDR && pixelFormat != MTLPixelFormatInvalid)
     {
         pixelFormat -= (MTLPixelFormatASTC_4x4_LDR - MTLPixelFormatASTC_4x4_sRGB);
     }

     return pixelFormat;
 }

 - (void)getASTCPixelFormat:(MTLPixelFormat)pixelFormat
                 blockWidth:(uint32_t *)outBlockWidth
                blockHeight:(uint32_t *)outBlockHeight
 {
     switch (pixelFormat) {
         case MTLPixelFormatASTC_4x4_LDR:
         case MTLPixelFormatASTC_4x4_sRGB:
             *outBlockHeight = 4;
             *outBlockWidth = 4;
             break;
         case MTLPixelFormatASTC_5x4_LDR:
         case MTLPixelFormatASTC_5x4_sRGB:
             *outBlockHeight = 5;
             *outBlockWidth = 4;
             break;
         case MTLPixelFormatASTC_5x5_LDR:
         case MTLPixelFormatASTC_5x5_sRGB:
             *outBlockHeight = 5;
             *outBlockWidth = 5;
             break;
         case MTLPixelFormatASTC_6x5_LDR:
         case MTLPixelFormatASTC_6x5_sRGB:
             *outBlockHeight = 6;
             *outBlockWidth = 5;
             break;
         case MTLPixelFormatASTC_6x6_LDR:
         case MTLPixelFormatASTC_6x6_sRGB:
             *outBlockHeight = 6;
             *outBlockWidth = 6;
             break;
         case MTLPixelFormatASTC_8x5_LDR:
         case MTLPixelFormatASTC_8x5_sRGB:
             *outBlockHeight = 8;
             *outBlockWidth = 5;
             break;
         case MTLPixelFormatASTC_8x6_LDR:
         case MTLPixelFormatASTC_8x6_sRGB:
             *outBlockHeight = 8;
             *outBlockWidth = 6;
             break;
         case MTLPixelFormatASTC_8x8_LDR:
         case MTLPixelFormatASTC_8x8_sRGB:
             *outBlockWidth = 8;
             *outBlockHeight = 8;
             break;
         case MTLPixelFormatASTC_10x5_LDR:
         case MTLPixelFormatASTC_10x5_sRGB:
             *outBlockHeight = 10;
             *outBlockWidth = 5;
             break;
         case MTLPixelFormatASTC_10x6_LDR:
         case MTLPixelFormatASTC_10x6_sRGB:
             *outBlockHeight = 10;
             *outBlockWidth = 6;
             break;
         case MTLPixelFormatASTC_10x8_LDR:
         case MTLPixelFormatASTC_10x8_sRGB:
             *outBlockHeight = 10;
             *outBlockWidth = 8;
             break;
         case MTLPixelFormatASTC_10x10_LDR:
         case MTLPixelFormatASTC_10x10_sRGB:
             *outBlockHeight = 10;
             *outBlockWidth = 10;
             break;
         case MTLPixelFormatASTC_12x10_LDR:
         case MTLPixelFormatASTC_12x10_sRGB:
             *outBlockHeight = 12;
             *outBlockWidth = 10;
             break;
         case MTLPixelFormatASTC_12x12_LDR:
         case MTLPixelFormatASTC_12x12_sRGB:
             *outBlockHeight = 12;
             *outBlockWidth = 12;
             break;
         default:
             *outBlockHeight = 0;
             *outBlockWidth = 0;
             break;
     }
 }


 - (BOOL)loadASTCImageData:(NSData *)imageData
 {
     MBEASTCHeader *header = (MBEASTCHeader *)[imageData bytes];

     uint32_t fileMagic = CFSwapInt32LittleToHost(header->magic);

     if (fileMagic != MBEASTCMagic)
     {
         return NO;
     }

     uint32_t width  = (header->xSize[2] << 16) + (header->xSize[1] << 8) + header->xSize[0];
     uint32_t height = (header->ySize[2] << 16) + (header->ySize[1] << 8) + header->ySize[0];
     uint32_t depth  = (header->zSize[2] << 16) + (header->zSize[1] << 8) + header->zSize[0];

     uint32_t widthInBlocks  =  (width + header->blockDimX - 1) / header->blockDimX;
     uint32_t heightInBlocks = (height + header->blockDimY - 1) / header->blockDimY;
     uint32_t depthInBlocks  =  (depth + header->blockDimZ - 1) / header->blockDimZ;

     uint32_t blockSize = 4 * 4;
     uint32_t dataLength = widthInBlocks * heightInBlocks * depthInBlocks * blockSize;

     NSData *levelData = [NSData dataWithBytes:[imageData bytes] + sizeof(MBEASTCHeader) length:dataLength];

     _width = width;
     _height = height;
     _bytesPerRow = widthInBlocks * blockSize;
     _mipmapCount = 1;
     _levels = @[levelData];

     // The ASTC header doesn't seem to tell us which colorspace we're in, so we assume LDR (as opposed to sRGB)
     _pixelFormat = [self pixelFormatForASTCBlockWidth:header->blockDimX
                                           blockHeight:header->blockDimY
                                       colorSpaceIsLDR:YES];

     return YES;
 }
 
 - (MTLPixelFormat)pixelFormatForGLInternalFormat:(MBEKTXInternalFormat)internalFormat
 {
     switch (internalFormat) {
         case MBEKTXInternalFormatASTC_4x4:
             return MTLPixelFormatASTC_4x4_LDR;
         case MBEKTXInternalFormatASTC_5x4:
             return MTLPixelFormatASTC_5x4_LDR;
         case MBEKTXInternalFormatASTC_5x5:
             return MTLPixelFormatASTC_5x5_LDR;
         case MBEKTXInternalFormatASTC_6x5:
             return MTLPixelFormatASTC_6x5_LDR;
         case MBEKTXInternalFormatASTC_6x6:
             return MTLPixelFormatASTC_6x6_LDR;
         case MBEKTXInternalFormatASTC_8x5:
             return MTLPixelFormatASTC_8x5_LDR;
         case MBEKTXInternalFormatASTC_8x6:
             return MTLPixelFormatASTC_8x6_LDR;
         case MBEKTXInternalFormatASTC_8x8:
             return MTLPixelFormatASTC_8x8_LDR;
         case MBEKTXInternalFormatASTC_10x5:
             return MTLPixelFormatASTC_10x5_LDR;
         case MBEKTXInternalFormatASTC_10x6:
             return MTLPixelFormatASTC_10x6_LDR;
         case MBEKTXInternalFormatASTC_10x8:
             return MTLPixelFormatASTC_10x8_LDR;
         case MBEKTXInternalFormatASTC_10x10:
             return MTLPixelFormatASTC_10x10_LDR;
         case MBEKTXInternalFormatASTC_12x10:
             return MTLPixelFormatASTC_12x10_LDR;
         case MBEKTXInternalFormatASTC_12x12:
             return MTLPixelFormatASTC_12x12_LDR;
         case MBEKTXInternalFormatASTC_4x4_sRGB:
             return MTLPixelFormatASTC_4x4_sRGB;
         case MBEKTXInternalFormatASTC_5x4_sRGB:
             return MTLPixelFormatASTC_5x4_sRGB;
         case MBEKTXInternalFormatASTC_5x5_sRGB:
             return MTLPixelFormatASTC_5x5_sRGB;
         case MBEKTXInternalFormatASTC_6x5_sRGB:
             return MTLPixelFormatASTC_6x5_sRGB;
         case MBEKTXInternalFormatASTC_6x6_sRGB:
             return MTLPixelFormatASTC_6x6_sRGB;
         case MBEKTXInternalFormatASTC_8x5_sRGB:
             return MTLPixelFormatASTC_8x5_sRGB;
         case MBEKTXInternalFormatASTC_8x6_sRGB:
             return MTLPixelFormatASTC_8x6_sRGB;
         case MBEKTXInternalFormatASTC_8x8_sRGB:
             return MTLPixelFormatASTC_8x8_sRGB;
         case MBEKTXInternalFormatASTC_10x5_sRGB:
             return MTLPixelFormatASTC_10x5_sRGB;
         case MBEKTXInternalFormatASTC_10x6_sRGB:
             return MTLPixelFormatASTC_10x6_sRGB;
         case MBEKTXInternalFormatASTC_10x8_sRGB:
             return MTLPixelFormatASTC_10x8_sRGB;
         case MBEKTXInternalFormatASTC_10x10_sRGB:
             return MTLPixelFormatASTC_10x10_sRGB;
         case MBEKTXInternalFormatASTC_12x10_sRGB:
             return MTLPixelFormatASTC_12x10_sRGB;
         case MBEKTXInternalFormatASTC_12x12_sRGB:
             return MTLPixelFormatASTC_12x12_sRGB;
         default:
             return MTLPixelFormatInvalid;
     }
 }
 
 - (BOOL)loadKTXImageData:(NSData *)data;
 {
     MBEKTXHeader *header = (MBEKTXHeader *)[data bytes];

     BOOL endianSwap = (header->endianness == 0x01020304);

     uint32_t width = endianSwap ? CFSwapInt32(header->width) : header->width;
     uint32_t height = endianSwap ? CFSwapInt32(header->height) : header->height;
     uint32_t internalFormat = endianSwap ? CFSwapInt32(header->glInternalFormat) : header->glInternalFormat;
     uint32_t mipCount = endianSwap ? CFSwapInt32(header->mipmapCount) : header->mipmapCount;
     uint32_t keyValueDataLength = endianSwap ? CFSwapInt32(header->keyValueDataLength) : header->keyValueDataLength;

     const uint8_t *bytes = [data bytes] + sizeof(MBEKTXHeader) + keyValueDataLength;
     const size_t dataLength = [data length] - (sizeof(MBEKTXHeader) + keyValueDataLength);

     NSMutableArray *levelDatas = [NSMutableArray arrayWithCapacity:MAX(mipCount, 1)];

     const uint32_t blockSize = 16;
     uint32_t dataOffset = 0;
     uint32_t levelWidth = width, levelHeight = height;
     while (dataOffset < dataLength)
     {
         uint32_t levelSize = *(uint32_t *)(bytes + dataOffset);
         dataOffset += sizeof(uint32_t);

         NSData *mipData = [NSData dataWithBytes:bytes + dataOffset length:levelSize];
         [levelDatas addObject:mipData];

         dataOffset += levelSize;

         levelWidth = MAX(levelWidth / 2, 1);
         levelHeight = MAX(levelHeight / 2, 1);
     }

     MTLPixelFormat pixelFormat = [self pixelFormatForGLInternalFormat:internalFormat];

     if (pixelFormat == MTLPixelFormatInvalid)
     {
         return NO;
     }

     uint32_t blockWidth, blockHeight;
     [self getASTCPixelFormat:pixelFormat blockWidth:&blockWidth blockHeight:&blockHeight];

     _pixelFormat = pixelFormat;
     _bytesPerRow = (width / blockWidth) * blockSize;
     _width = width;
     _height = height;
     _levels = [levelDatas copy];
     _mipmapCount = [levelDatas count];

     return YES;
 }

 
 */
