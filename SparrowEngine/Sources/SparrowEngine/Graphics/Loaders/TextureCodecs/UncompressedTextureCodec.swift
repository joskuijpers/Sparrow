//
//  UncompressedTextureCodec.swift
//  
//
//  Created by Jos Kuijpers on 16/06/2020.
//

import Metal
import Cocoa

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
