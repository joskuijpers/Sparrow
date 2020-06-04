//
//  SPMFileWriter.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

/// A writer for mesh to the file system.
public class SPMFileWriter {
    private let file: SPMFile
    
    private init(file: SPMFile) {
        self.file = file
    }
    
    /// Get the bytes of the asset.
    private func toBytes() throws -> [UInt8] {
        return try BinaryEncoder.encode(file)
    }
    
    /// Write the asset to given URL
    public static func write(_ file: SPMFile, to url: URL) throws {
        let writer = SPMFileWriter(file: file)
        
        let data = Data(try writer.toBytes())
        try data.write(to: url)
        
        print("Written SparrowMesh of \(data.count / 1024) KiB to \(url.path)")
    }
    
    /// Write the asset in the reference to the url in the reference.
    public static func write(_ fileRef: SPMFileRef) throws {
        try write(fileRef.file, to: fileRef.url)
    }
    
    /// Write the asset to a Data instance.
    public static func write(_ file: SPMFile, to data: inout Data) throws {
        let writer = SPMFileWriter(file: file)

        try data.append(contentsOf: writer.toBytes())
    }
}
