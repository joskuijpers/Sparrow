//
//  TextureTools.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 23/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal
import Foundation

/// Content of a channel: either another image or a color
enum ChannelContent {
    case image(URL)
    case color(Float)
}

protocol TextureTool {
    init(verbose: Bool)
    
    func waitUntilFinished()
    
    /// Convert an image to a greyscale variant
    func convert(_ input: URL, toGrayscaleImage output: URL) throws
    
    /// Write an image to another path, possibly changing format.
    func convert(_ input: URL, to output: URL, allowingAlpha: Bool) throws
    
    /// Combine 3 images into a single RGB image.
    func combine(red: ChannelContent, green: ChannelContent, blue: ChannelContent, into output: URL, size requestedSize: MTLSize?) throws
}

// Get red channel from RGB image:          convert -channel R -separate ./SparrowEngine/SparrowEngine/Models/grass_albedo.png ./r.png

