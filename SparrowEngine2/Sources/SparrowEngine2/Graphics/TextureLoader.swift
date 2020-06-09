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
    
    /// Errors returned by the texture loader.
    enum Error: Swift.Error {
        
    }
}

/// A texture.
public class Texture {
    public let imageName: String
    public let mtlTexture: MTLTexture
}


/*
 
 ASTC texture loading
 https://metalbyexample.com/compressed-textures/
 
 struct ASTCHeader {
     uint32_t magic;
     unsigned char blockDimX;
     unsigned char blockDimY;
     unsigned char blockDimZ;
     unsigned char xSize[3];
     unsigned char ySize[3];
     unsigned char zSize[3];
 };
 

 typedef struct __attribute__((packed))
 {
     uint8_t identifier[12];
     uint32_t endianness;
     uint32_t glType;
     uint32_t glTypeSize;
     uint32_t glFormat;
     uint32_t glInternalFormat;
     uint32_t glBaseInternalFormat;
     uint32_t width;
     uint32_t height;
     uint32_t depth;
     uint32_t arrayElementCount;
     uint32_t faceCount;
     uint32_t mipmapCount;
     uint32_t keyValueDataLength;
 } MBEKTXHeader;

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
 
 + (BOOL)dataIsASTCContainer:(NSData *)data
 {
     if ([data length] < sizeof(MBEASTCHeader))
     {
         return NO;
     }

     MBEASTCHeader *header = (MBEASTCHeader *)[data bytes];
     uint32_t fileMagic = CFSwapInt32LittleToHost(header->magic);
     return (fileMagic == MBEASTCMagic);
 }

 + (BOOL)dataIsKTXContainer:(NSData *)data
 {
     if ([data length] < sizeof(MBEKTXHeader))
     {
         return NO;
     }

     MBEKTXHeader *header = (MBEKTXHeader *)[data bytes];
     char *format = (char *)(header->identifier + 1);
     return strncmp(format, "KTX 11", 6) == 0;
 }
 
 + (MBETextureContainerFormat)inferredContainerFormatForData:(NSData *)data
 {
     if ([self dataIsProbablyNotHardwareCompressed:data])
     {
         return MBETextureContainerFormatNotHardwareCompressed;
     }
     else if ([self dataIsPVRv2Container:data])
     {
         return MBETextureContainerFormatPVRv2;
     }
     else if ([self dataIsPVRv3Container:data])
     {
         return MBETextureContainerFormatPVRv3;
     }
     else if ([self dataIsASTCContainer:data])
     {
         return MBETextureContainerFormatASTC;
     }
     else if ([self dataIsKTXContainer:data])
     {
         return MBETextureContainerFormatKTX;
     }

     return MBETextureContainerFormatUnknown;
 }
 

 + (BOOL)dataIsProbablyNotHardwareCompressed:(NSData *)data
 {
     if (data.length == 0)
         return YES;

     uint8_t c = 0;
     [data getBytes:&c length:1];

     switch (c) {
         case 0xFF: // JPEG
         case 0x89: // PNG
         case 0x47: // GIF
         case 0x49: // TIFF
         case 0x4D: // TIFF
             return YES;
         default:
             return NO;
     }
 }
 
 - (BOOL)loadTextureData:(NSData *)data containerFormat:(MBETextureContainerFormat)containerFormat
 {
     switch (containerFormat)
     {
         case MBETextureContainerFormatNotHardwareCompressed:
             [self loadImageData:data];
             break;
         case MBETextureContainerFormatPVRv2:
             [self loadPVRv2ImageData:data];
             break;
         case MBETextureContainerFormatPVRv3:
             [self loadPVRv3ImageData:data];
             break;
         case MBETextureContainerFormatASTC:
             [self loadASTCImageData:data];
             break;
         case MBETextureContainerFormatKTX:
             [self loadKTXImageData:data];
             break;
         default:
             break;
     }

     return NO;
 }

 - (BOOL)loadImageData:(NSData *)imageData
 {
     UIImage *image = [UIImage imageWithData:imageData];
     CGImageRef imageRef = image.CGImage;

     // Create a suitable bitmap context for extracting the bits of the image
     const NSUInteger width = CGImageGetWidth(imageRef);
     const NSUInteger height = CGImageGetHeight(imageRef);
     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
     const NSUInteger dataLength = height * width * 4;
     uint8_t *rawData = (uint8_t *)calloc(dataLength, sizeof(uint8_t));
     const NSUInteger bytesPerPixel = 4;
     const NSUInteger bytesPerRow = bytesPerPixel * width;
     const NSUInteger bitsPerComponent = 8;
     CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                  bitsPerComponent, bytesPerRow, colorSpace,
                                                  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
     CGColorSpaceRelease(colorSpace);

     CGRect imageRect = CGRectMake(0, 0, width, height);
     CGContextDrawImage(context, imageRect, imageRef);

     CGContextRelease(context);

     _pixelFormat = MTLPixelFormatRGBA8Unorm;
     _width = width;
     _height = height;
     _bytesPerRow = bytesPerRow;
     _mipmapCount = 1;
     _levels = @[[NSData dataWithBytesNoCopy:rawData length:dataLength freeWhenDone:YES]];

     return YES;
 }

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

 
 - (id<MTLTexture>)newTextureWithCommandQueue:(id<MTLCommandQueue>)commandQueue generateMipmaps:(BOOL)generateMipmaps
 {
     if ([self.levels count] > 0)
     {
         BOOL mipsLoaded = ([self.levels count] > 1);
         BOOL canGenerateMips = [self pixelFormatIsColorRenderable:self.pixelFormat];

         if (mipsLoaded || !canGenerateMips)
         {
             generateMipmaps = NO;
         }

         BOOL needMipStorage = (generateMipmaps || mipsLoaded);

         MTLTextureDescriptor *texDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat
                                                                                                  width:self.width
                                                                                                 height:self.height
                                                                                              mipmapped:needMipStorage];
         id<MTLTexture> texture = [[commandQueue device] newTextureWithDescriptor:texDescriptor];

         __block NSInteger levelWidth = self.width;
         __block NSInteger levelHeight = self.height;
         __block NSInteger levelBytesPerRow = self.bytesPerRow;

         [self.levels enumerateObjectsUsingBlock:^(NSData *levelData, NSUInteger level, BOOL *stop) {
             MTLRegion region = MTLRegionMake2D(0, 0, levelWidth, levelHeight);
             [texture replaceRegion:region mipmapLevel:level withBytes:[levelData bytes] bytesPerRow:levelBytesPerRow];

             levelWidth = MAX(levelWidth / 2, 1);
             levelHeight = MAX(levelHeight / 2, 1);
             levelBytesPerRow = (levelBytesPerRow > 0) ? MAX(levelBytesPerRow / 2, 16) : 0;
         }];

         if (generateMipmaps)
         {
             [self generateMipmapsForTexture:texture commandQueue:commandQueue];
         }

         return texture;
     }

     return nil;
 }

 - (void)generateMipmapsForTexture:(id<MTLTexture>)texture commandQueue:(id<MTLCommandQueue>)commandQueue
 {
     id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
     id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
     [blitEncoder generateMipmapsForTexture:texture];
     [blitEncoder endEncoding];
     [commandBuffer commit];

     // blocking call
     [commandBuffer waitUntilCompleted];
 }
 
 typedef NS_ENUM(NSInteger, MBETextureContainerFormat)
 {
     MBETextureContainerFormatUnknown = -1,
     MBETextureContainerFormatNotHardwareCompressed, // PNG, JPG, etc.
     MBETextureContainerFormatASTC,
     MBETextureContainerFormatPVRv2,
     MBETextureContainerFormatPVRv3,
     MBETextureContainerFormatKTX,
 };
 
 const uint32_t MBEPVRLegacyMagic = 0x21525650;
 const uint32_t MBEPVRv3Magic = 0x03525650;
 const uint32_t MBEASTCMagic = 0x5CA1AB13;
 const uint32_t MBEKTXMagic = 0xAB4B5458;
 
 */
