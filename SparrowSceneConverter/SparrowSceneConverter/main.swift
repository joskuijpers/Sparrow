//
//  main.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import SparrowAsset
import Metal

func main() {
    let url1 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/IronSphere/ironSphere.obj")
    let url2 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Sponza/sponza.obj")
    let url3 = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Elemental/Elemental.obj")

    let url = url1

    do {
        let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Assets/\(url.deletingLastPathComponent().lastPathComponent)/\(url.deletingPathExtension().lastPathComponent).spa")
        
        // Import asset from .obj file
        let fileRef = try ObjImporter.import(from: url, to: outputUrl, options: [.generateTangents, .uniformScale(1)])
        
        // All textures are relative to the import asset url, which is pretty useless if we write the output somewhere else...
        
        // Output in binary
        try FileManager.default.createDirectory(at: outputUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        try SparrowAssetWriter.write(fileRef.asset, to: outputUrl)
        
        let urls = fileRef.asset.textures.map { URL(fileURLWithPath: $0.relativePath, relativeTo: outputUrl) }
        print("Number of textures: \(urls.count), of which unique: \(Set(urls).count)")
        print("Number of materials in asset: \(fileRef.asset.materials.count)")
    } catch {
        print("Error: \(error)")
    }
}

main()

/*

 class SAFileRef
    asset: SAAsset
    url: URL

 converter needs input (.obj) and output (.spa) path
 then we need to copy needed assets with new names to the output path
 name textures '<obj>_<mat>_<type>.png'
 
 
 We can make an editor for asset files to change all of this... we only store relative paths so we can easily re-point to a different texture
 Normally you'd do this with a proper exporter I guess
 
 */
