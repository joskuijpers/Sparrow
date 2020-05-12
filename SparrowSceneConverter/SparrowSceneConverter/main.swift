//
//  main.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import SparrowAsset

import CoreGraphics
import ImageIO
import Metal

//import StickyEncoding

/*
 
 Reading GTLF: https://github.com/warrenm/GLTFKit
 Reading OBJ: self-made
 
 Writing SA: self-made -> In engine / SparrowAsset framework
 Reading SA: self-made -> In engine / SparrowAsset framework
 
 // RMA: Roughness Metalness AmbientOcclusion
 
 Converter: In this program
 
 */

/// Texture class with functionality for loading, saving, channel overwriting
class Texture {
    let url: URL
    let props: [String:Any]
    let image: CGImage
    var bitmapContext: CGContext?
    
    var size: MTLSize {
        let width = props[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let depth = props[kCGImagePropertyDepth as String] as? Int ?? 1
        
        return MTLSizeMake(width, height, depth)
    }
    
    var hasAlpha: Bool {
        let hasAlpha = props[kCGImagePropertyHasAlpha as String] as? UInt ?? 0
        return hasAlpha == 1
    }
    
    init(url: URL) {
        self.url = url
        
        // Get image
        let options = [
            kCGImageSourceShouldCache as String : true as NSNumber,
            kCGImageSourceShouldAllowFloat as String : true as NSNumber
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options) else {
            fatalError("Could not open \(url.path)")
        }
        
        guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            fatalError("Could not find image in source \(url.path)")
        }
        
        props = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String:Any] ?? [:]
        self.image = image
    }
    
    /// Write to given URL
    func write(url: URL) {
        // Destination options
        let destOpts = [
            kCGImagePropertyHasAlpha as String : true as NSNumber
        ] as CFDictionary
        
        guard let imageDest = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
            fatalError("Could not create image destination at \(url.path)")
        }
        CGImageDestinationAddImage(imageDest, image, destOpts)
        CGImageDestinationFinalize(imageDest)
    }
    
    private func createBitmapData() {
        let size = self.size
        
        let bytesPerRow = size.width * 4
        let byteCount = bytesPerRow * size.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let data = malloc(byteCount) else {
            fatalError("Could not allocate memory for image")
        }
        
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        bitmapContext = CGContext(data: data, width: size.width, height: size.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: info.rawValue)
        bitmapContext?.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }
    
    func color(x: Int, y: Int) -> SIMD4<Float> {
        if bitmapContext == nil {
            createBitmapData()
        }
        if bitmapContext == nil {
            fatalError("Cannot load bitmap")
        }
        
        let uncasted_data = bitmapContext?.data!
        let data = uncasted_data?.assumingMemoryBound(to: UInt8.self)
        
        let offset = 4 * (y * size.width + x)
        
        let red = data![offset + 0]
        let green = data![offset + 1]
        let blue = data![offset + 2]
        let alpha = data![offset + 3]

        return [Float(red) / 255.0, Float(green) / 255.0, Float(blue) / 255.0, Float(alpha) / 255.0]
    }
}

func getAlbedoTexturePath(asset: SAAsset, material: SAMaterial) -> String? {
    switch material.albedo {
    case .texture(let index):
        return asset.textures[index].relativePath
    default:
        return nil
    }
}

let url1 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/ironSphere.obj") // 48% -> 35%
let url2 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/SPONZA/sponza.obj") // 45% -> 35%
let url3 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/RAW/Elemental/Elemental.obj") // 44% -> 33%

let url = url1

do {
    // Import asset from .obj file
    let asset = try ObjImporter.import(from: url)
    
    // Output in binary
    let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/\(url.deletingPathExtension().lastPathComponent).spa")
    try SparrowAssetWriter.write(asset, to: outputUrl)
    
    let roundTrip = try SparrowAssetLoader.load(from: outputUrl)
    
    print("INPUT     \(String(describing: getAlbedoTexturePath(asset: asset, material: asset.materials[0])))")
    print("ROUNDTRIP \(String(describing: getAlbedoTexturePath(asset: roundTrip, material: roundTrip.materials[0])))")
    
} catch {
    print(error)
}


