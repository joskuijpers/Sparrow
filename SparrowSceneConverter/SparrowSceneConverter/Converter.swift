//
//  Converter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 25/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowMesh
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
//        let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/glTF-Sample-Models/2.0/Sponza/glTF/Sponza.gltf")
//        let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Sponza/sponza.obj")
//        let url = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/Scenes/Elemental/Elemental.obj")

        let fileRef = try convert(url: url)
        
        printAssetSummary(fileRef)
    }
}

extension Converter {
    
    func convert(url: URL) throws -> SPMFileRef {
        let name = url.deletingPathExtension().lastPathComponent // + "_gltf"
        let outputUrl = URL(fileURLWithPath: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Assets/\(name)/\(name).spm")
        
        // Import asset from .obj file
        let start = DispatchTime.now()
//        let fileRef = try GLTFImporter.import(from: url, to: outputUrl, options: [])
        let fileRef = try ObjImporter.import(from: url, to: outputUrl, options: [.generateTangents, .uniformScale(1)])
        let end = DispatchTime.now()
        
        print(fileRef.file)

        print("Import duration: \(Int(ceil(Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000))) seconds")
        
        // Create folders if needed
        try FileManager.default.createDirectory(at: outputUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Write in binary
        try SPMFileWriter.write(fileRef)
        
        return fileRef
    }
    
    func printAssetSummary(_ fileRef: SPMFileRef) {
        print()
        print("Asset info:")
        
        let urls = fileRef.file.textures.map { URL(fileURLWithPath: $0.relativePath, relativeTo: fileRef.url).absoluteURL }
        print("  Number of textures: \(urls.count), of which unique: \(Set(urls).count)")
        print("  Number of materials: \(fileRef.file.materials.count)")
        print("  Number of meshes: \(fileRef.file.mesh == nil ? 0 : 1)")
        print("  Number of submeshes: \(fileRef.file.mesh?.submeshes.count ?? 0))")
        print("  Number of buffers: \(fileRef.file.buffers.count)")
        print("  Number of bufferviews: \(fileRef.file.bufferViews.count)")
    }

}
