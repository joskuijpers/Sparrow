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

let url = url1

do {
    // Import asset from .obj file
    let asset = try ObjImporter.import(from: url, options: [.generateTangents, .uniformScale(0.01)])
    
    // Output in binary
    let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/\(url.deletingPathExtension().lastPathComponent).spa")
    try SparrowAssetWriter.write(asset, to: outputUrl)
    
    for texture in asset.textures {
        let u = URL(fileURLWithPath: texture.relativePath, relativeTo: outputUrl)
        print("Using texture at \(u.path) with size \(try TextureUtil.size(of: u))")
    }
} catch {
    print(error)
}

