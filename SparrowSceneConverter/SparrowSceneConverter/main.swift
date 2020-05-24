//
//  main.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import SparrowAsset

func main() {
    let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/IronSphere/ironSphere.obj")
//    let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Sponza/sponza.obj")
//    let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Elemental/Elemental.obj")

    do {
        let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Assets/\(url.deletingLastPathComponent().lastPathComponent)/\(url.deletingPathExtension().lastPathComponent).spa")
        
        // Import asset from .obj file
        let fileRef = try ObjImporter.import(from: url, to: outputUrl, options: [.generateTangents, .uniformScale(0.01)])
        
        // Create folders if needed
        try FileManager.default.createDirectory(at: outputUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Write in binary
        try SparrowAssetWriter.write(fileRef)

        
        // Some asset info
        print()
        print("Asset info:")
        
        let urls = fileRef.asset.textures.map { URL(fileURLWithPath: $0.relativePath, relativeTo: outputUrl) }
        print("  Number of textures: \(urls.count), of which unique: \(Set(urls).count)")
        print("  Number of materials in asset: \(fileRef.asset.materials.count)")
    } catch {
        print("Error: \(error)")
        exit(1)
    }
    
    exit(0)
}

main()
