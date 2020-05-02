//
//  main.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd
import CoreGraphics
import ImageIO
import Metal

class Converter {
    let aiScene: AiScene
    let sourceUrl: URL
    let destUrl: URL
    let destUrlFolder: URL
    
    init(url: URL) throws {
        sourceUrl = url

        aiScene = try AiScene(file: sourceUrl.path,
                              flags: [.removeRedundantMaterials, .genSmoothNormals])
        
        // Create new asset URL (hacky)
        let filename = sourceUrl.lastPathComponent
        
        destUrl = sourceUrl
            .deletingLastPathComponent()
            .appendingPathComponent("sa", isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
            .deletingPathExtension()
            .appendingPathExtension("sa")
        destUrlFolder = destUrl.deletingLastPathComponent()

        // Create destination folder
        try FileManager.default.createDirectory(at: destUrlFolder, withIntermediateDirectories: true, attributes: nil)
        
        print("FROM\n\t\(sourceUrl.path)\nTO\n\t\(destUrl.path)")
        print(destUrlFolder.path)
    }

    /// Create a normalized SA material with proper image channels
    func createMaterial(aiMaterial: AiMaterial) -> SAMaterial {
        let name = aiMaterial.name ?? "material"
        
        // Albedo and alpha
        let albedoTexture = createAlbedoTexture(aiMaterial: aiMaterial)
        
        // Create a color version
        let albedoColor = aiMaterial.getMaterialColor(.COLOR_DIFFUSE) ?? SIMD4<Float>(0, 0, 0, 1)
        let opacity = (aiMaterial.getMaterialFloatArray(.OPACITY) ?? [1.0]).first ?? 1.0
        let albedoMultiplier = SIMD4<Float>(1, 1, 1, opacity)
        
        let albedo = createMaterialProperty(texture: albedoTexture, color: albedoColor * albedoMultiplier)

        // Normal map
        let normalMap = aiMaterial.getMaterialTexture(texType: .normals, texIndex: 0) ?? aiMaterial.getMaterialTexture(texType: .height, texIndex: 0)
        let normals = createMaterialProperty(texture: normalMap, color: nil)
        
        // Metalness, roughness and AO
        let mro = createMaterialProperty(texture: createMetalnessRoughnessAO(aiMaterial: aiMaterial), color: SIMD4<Float>(0, 0, 0, 0))

        // Emissive
        let emissiveTextureIn = aiMaterial.getMaterialTexture(texType: .emissive, texIndex: 0) ?? aiMaterial.getMaterialTexture(texType: .emissionColor, texIndex: 0)
        let emissiveTexture = copyTexture(input: emissiveTextureIn, numChannels: 3)
        let emissive: SAMaterialProperty = createMaterialProperty(texture: emissiveTexture, color: SIMD4<Float>(0, 0, 0, 0))
        
        return SAMaterial(name: name, albedo: albedo, normals: normals, metalnessRoughnessOcclusion: mro, emissive: emissive, blendMode: 0, alphaMode: 0)
    }

    /// Create a material property
    func createMaterialProperty(texture: URL?, color: SIMD4<Float>?) -> SAMaterialProperty {
        if let url = texture {
            return SAMaterialProperty.Texture(url)
        } else if let color = color {
            return SAMaterialProperty.Color(color)
        } else {
            return SAMaterialProperty.None
        }
    }

    func createMaterialProperty(texture: String?, color: SIMD4<Float>?) -> SAMaterialProperty {
        if let texture = texture {
            return createMaterialProperty(texture: URL(fileURLWithPath: texture, relativeTo: destUrl), color: color)
        } else {
            let texture: URL? = nil
            return createMaterialProperty(texture: texture, color: color)
        }
    }
    
    func createAlbedoTexture(aiMaterial: AiMaterial) -> URL? {
        let albedoPath = aiMaterial.getMaterialTexture(texType: .baseColor, texIndex: 0) ?? aiMaterial.getMaterialTexture(texType: .diffuse, texIndex: 0)
        let opacityPath = aiMaterial.getMaterialTexture(texType: .opacity, texIndex: 0)
        
        if opacityPath != nil || albedoPath != nil {
            if opacityPath == nil {
                // Copy the whole albedo texture
                return copyTexture(input: albedoPath, numChannels: 4)
            } else {
                print("[texture] Create new albedo texture with opacity")
                return copyTexture(input: albedoPath, numChannels: 4)
            }
        } else {
            return nil
        }
    }
    
    func createMetalnessRoughnessAO(aiMaterial: AiMaterial) -> URL? {
        let inMetalness = aiMaterial.getMaterialTexture(texType: .metalness, texIndex: 0) ?? aiMaterial.getMaterialTexture(texType: .ambient, texIndex: 0)
        let inRoughness = aiMaterial.getMaterialTexture(texType: .diffuseRoughness, texIndex: 0) ?? aiMaterial.getMaterialTexture(texType: .shininess, texIndex: 0)
        let inAO = aiMaterial.getMaterialTexture(texType: .ambientOcclusion, texIndex: 0)
        
        print("[texture] Metalness \(inMetalness)")
        print("[texture] Roughness \(inRoughness)")
        print("[texture] AO \(inAO)")
        
        return copyTexture(input: inMetalness, numChannels: 4)
//        return URL(fileURLWithPath: "mrao.tga", relativeTo: destUrl)
    }
    
    func copyTexture(input: String?, numChannels: UInt) -> URL? {
        guard let input = input else {
            return nil
        }
        
        let inputUrl = URL(fileURLWithPath: input, relativeTo: sourceUrl)
        let outputUrl = URL(fileURLWithPath: input, relativeTo: destUrlFolder).deletingPathExtension().appendingPathExtension("png")
        
        print("[texture] Copy \(inputUrl.path) keeping \(numChannels) channels")
        
        let texture = Texture(url: inputUrl)

        print("Image size: \(texture.size)")
        print("Has alpha: \(texture.hasAlpha)")
            
        texture.write(url: outputUrl)
        
        print(texture.color(x: 10, y: 10))
        
        return outputUrl
    }
}

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



let url1 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/ironSphere.obj")
let url2 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/SPONZA/sponza.obj")

let converter = try Converter(url: url2)

print("")
for material in converter.aiScene.materials {
    print(converter.createMaterial(aiMaterial: material))
}
