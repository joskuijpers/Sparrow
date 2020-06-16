//
//  KTXTextureCodec.swift
//  
//
//  Created by Jos Kuijpers on 16/06/2020.
//

import CSparrowEngine
import Foundation

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
