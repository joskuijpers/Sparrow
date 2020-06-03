//
//  SparrowAssetWriter.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

/// A writer for asset to the file system.
public class SparrowAssetWriter {
    private let asset: SAAsset
    
    private init(asset: SAAsset) {
        self.asset = asset
    }
    
    /// Get the bytes of the asset.
    private func toBytes() throws -> [UInt8] {
        return try BinaryEncoder.encode(asset)
    }
    
    /// Write the asset to given URL
    public static func write(_ asset: SAAsset, to url: URL) throws {
        let writer = SparrowAssetWriter(asset: asset)
        
        let data = Data(try writer.toBytes())
        try data.write(to: url)
        
        print("Written SparrowAsset of \(data.count / 1024) KiB to \(url.path)")
    }
    
    /// Write the asset in the reference to the url in the reference.
    public static func write(_ fileRef: SAFileRef) throws {
        try write(fileRef.asset, to: fileRef.url)
    }
    
    /// Write the asset to a Data instance.
    public static func write(_ asset: SAAsset, to data: inout Data) throws {
        let writer = SparrowAssetWriter(asset: asset)

        try data.append(contentsOf: writer.toBytes())
    }
}
