//
//  Converter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 25/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowAsset
import ArgumentParser

struct Converter: ParsableCommand {
    
    static var configuration = CommandConfiguration(
//        commandName: ,
        abstract: "A tool to convert OBJ and GLTF files to the Sparrow Asset format (.spa)",
        discussion: "A discussion",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong
    )

    func run() throws {
        let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/IronSphere/ironSphere.obj")
//        let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Sponza/sponza.obj")
//        let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Elemental/Elemental.obj")

        let fileRef = try convert(url: url)
        
        printAssetSummary(fileRef)
    }
}

extension Converter {
    
    func convert(url: URL) throws -> SAFileRef {
        let name = url.deletingLastPathComponent().lastPathComponent
        let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Assets/\(name)/\(name).spa")
        
        // Import asset from .obj file
        let start = DispatchTime.now()
        let fileRef = try ObjImporter.import(from: url, to: outputUrl, options: [.generateTangents, .uniformScale(0.01)])
        let end = DispatchTime.now()

        print("Import duration: \(Int(ceil(Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000))) seconds")
        
        // Create folders if needed
        try FileManager.default.createDirectory(at: outputUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Write in binary
        try SparrowAssetWriter.write(fileRef)
        
        return fileRef
    }
    
    func printAssetSummary(_ fileRef: SAFileRef) {
        print()
        print("Asset info:")
        
        let urls = fileRef.asset.textures.map { URL(fileURLWithPath: $0.relativePath, relativeTo: fileRef.url).absoluteURL }
        print("  Number of textures: \(urls.count), of which unique: \(Set(urls).count)")
        print("  Number of materials: \(fileRef.asset.materials.count)")
        print("  Number of meshes: \(fileRef.asset.meshes.count)")
        print("  Number of submeshes: \(fileRef.asset.meshes.reduce(0,{ $0 + $1.submeshes.count }))")
        print("  Number of buffers: \(fileRef.asset.buffers.count)")
        print("  Number of bufferviews: \(fileRef.asset.bufferViews.count)")
    }

}
