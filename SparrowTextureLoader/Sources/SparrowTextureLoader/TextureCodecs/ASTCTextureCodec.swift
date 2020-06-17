//
//  ASTCTextureCodec.swift
//  
//
//  Created by Jos Kuijpers on 16/06/2020.
//

import Metal
import CSparrowTextureLoader

#if os(iOS)

@available(iOS 8.0, *)
struct ASTCTextureCodec: TextureCodec {
    static let magic: UInt32 = 0x5CA1AB13

    enum Error: Swift.Error {
        /// The file format is invalid.
        case corrupted
    }
    
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
        let header = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> ASTCHeader in
            ptr.load(as: ASTCHeader.self)
        }
        
        let fileMagic = CFSwapInt32LittleToHost(header.magic)
        if fileMagic != Self.magic {
            throw Error.corrupted
        }
        
        let width = parseSize(header.xSize)
        let height = parseSize(header.ySize)
        let depth = parseSize(header.zSize)
        print("WIDTH \(width) HEIGHT \(height) DEPTH \(depth)")
        
        let widthInBlocks = (width + Int(header.blockDimX) - 1) / Int(header.blockDimX)
        let heightInBlocks = (height + Int(header.blockDimY) - 1) / Int(header.blockDimY)
        let depthInBlocks = (depth + Int(header.blockDimZ) - 1) / Int(header.blockDimZ)
        
        print("WIDTH \(widthInBlocks) HEIGHT \(heightInBlocks) DEPTH \(depthInBlocks)")
        
        let blockSize = 4 * 4
        let dataLength = widthInBlocks * heightInBlocks * depthInBlocks * blockSize
        let pixelFormat = pixelFormatForBlock(width: header.blockDimX, height: header.blockDimY, colorSpaceIsLDR: true)
        let level = data.advanced(by: MemoryLayout<ASTCHeader>.size).prefix(through: dataLength)
        
        return TextureDescriptor(pixelFormat: pixelFormat,
                                 width: width,
                                 height: height,
                                 mipmapCount: 1,
                                 bytesPerRow: widthInBlocks * blockSize,
                                 levels: [level])
    }
    
    @inline(__always)
    private func parseSize(_ input: (UInt8, UInt8, UInt8)) -> Int {
        let value = UInt32(input.2) << 16 + UInt32(input.1) << 8 + UInt32(input.0)
        return Int(value)
    }
    
    private func pixelFormatForBlock(width: UInt8, height: UInt8, colorSpaceIsLDR: Bool) -> MTLPixelFormat {
        return .astc_4x4_srgb
        
//
//        MTLPixelFormat pixelFormat = MTLPixelFormatInvalid;
//
//        if (blockWidth == 4)
//        {
//            if (blockHeight == 4)
//            {
//                pixelFormat = MTLPixelFormatASTC_4x4_LDR;
//            }
//        }
//        else if (blockWidth == 5)
//        {
//            if( blockHeight == 4)
//            {
//                pixelFormat = MTLPixelFormatASTC_5x4_LDR;
//            }
//            else if (blockHeight == 5)
//            {
//                pixelFormat = MTLPixelFormatASTC_5x5_LDR;
//            }
//        }
//        else if (blockWidth == 6)
//        {
//            if( blockHeight == 5)
//            {
//                pixelFormat = MTLPixelFormatASTC_6x5_LDR;
//            }
//            else if (blockHeight == 6)
//            {
//                pixelFormat = MTLPixelFormatASTC_6x6_LDR;
//            }
//        }
//        else if (blockWidth == 8)
//        {
//            if( blockHeight == 5)
//            {
//                pixelFormat = MTLPixelFormatASTC_8x5_LDR;
//            }
//            else if (blockHeight == 6)
//            {
//                pixelFormat = MTLPixelFormatASTC_8x6_LDR;
//            }
//            else if (blockHeight == 8)
//            {
//                pixelFormat = MTLPixelFormatASTC_8x8_LDR;
//            }
//        }
//        else if (blockWidth == 10)
//        {
//            if( blockHeight == 5)
//            {
//                pixelFormat = MTLPixelFormatASTC_10x5_LDR;
//            }
//            else if (blockHeight == 6)
//            {
//                pixelFormat = MTLPixelFormatASTC_10x6_LDR;
//            }
//            else if (blockHeight == 8)
//            {
//                pixelFormat = MTLPixelFormatASTC_10x8_LDR;
//            }
//            else if (blockHeight == 10)
//            {
//                pixelFormat = MTLPixelFormatASTC_10x10_LDR;
//            }
//        }
//        else if (blockWidth == 12)
//        {
//            if (blockHeight == 10)
//            {
//                pixelFormat = MTLPixelFormatASTC_12x10_LDR;
//            }
//            else if (blockHeight == 12)
//            {
//                pixelFormat = MTLPixelFormatASTC_12x12_LDR;
//            }
//        }
//
//        // Adjust pixel format if we're actually sRGB instead of LDR
//        if (!colorSpaceIsLDR && pixelFormat != MTLPixelFormatInvalid)
//        {
//            pixelFormat -= (MTLPixelFormatASTC_4x4_LDR - MTLPixelFormatASTC_4x4_sRGB);
//        }
//
//        return pixelFormat;
    }
}

#endif
