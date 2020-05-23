//
//  main.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import SparrowAsset
import Metal

let url1 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/ironSphere.obj") // 48% -> 35%
let url2 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/SPONZA/sponza.obj") // 45% -> 35%
let url3 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/RAW/Elemental/Elemental.obj") // 44% -> 33%

let url = url2

do {
    // Import asset from .obj file
    let asset = try ObjImporter.import(from: url, options: [.generateTangents, .uniformScale(0.01)])
    
    // All textures are relative to the import asset url, which is pretty useless if we write the output somewhere else...
    
    
    // Output in binary
    let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/\(url.deletingPathExtension().lastPathComponent).spa")
    try SparrowAssetWriter.write(asset, to: outputUrl)
    
    let textureTool = TextureTool()
    for texture in asset.textures {
        let u = URL(fileURLWithPath: texture.relativePath, relativeTo: outputUrl)
//        print("Using texture at \(u.path) with size \(try textureTool.size(of: u))")
    }
    
    let urls = asset.textures.map { URL(fileURLWithPath: $0.relativePath, relativeTo: outputUrl) }
    print("NUM UNIQUE TEXTURES \(Set(urls).count)")
    print("NUM MATERIALS IN ASSET \(asset.materials.count)")
    
} catch {
    print(error)
}

/*
Sponza.spabundle/
    sponza.spa
    Textures/
        ....png
        ....png
 

 class SAFileRef
    asset: SAAsset
    url: URL
 
 SABundle
    fileRef: SAFileRef
 
 SparrowAssetBundleWriter
    write(fileRef, to: url)
        // Make folders
        // For each texture: copy texture, adjust relative texture path
        // Write SAAsset
        // Done
 
 SparrowAssetBundleReader ??
    read(from: url) -> Bundle
        //
 
 
 // Turn TextureUtil into TextureTool instances. Keep file resolution cache. Add versbose
 // Make materials unique in ObjImporter so we don't handle textures multiple times
 // Fix origin of TGA files
 
 
 
 */
