//
//  TextureTools.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 23/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal
import Foundation

class TextureTool {
    let verbose: Bool
    var knownSizes: [URL:MTLSize] = [:]

    enum Error: Swift.Error {
        case commandFailed(String)
        
        /// Command have invalid output
        case invalidCommandOutput
    }
    
    init(verbose: Bool = false) {
        self.verbose = verbose
    }
    
    @discardableResult
    private func runCommand(arguments: [String]) throws -> String? {
        let task = Process()
        
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/magick")
        task.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        if verbose {
            print("[imagemagick] Execute with arguments: \((task.arguments ?? []))")
        }
        
        try task.run()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if errorData.count > 0 {
            throw Error.commandFailed(String(decoding: errorData, as: UTF8.self))
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(decoding: outputData, as: UTF8.self)
        
        if outputString.count > 0 {
            return outputString
        } else {
            return nil
        }
    }
    
    /// Convert an image to a greyscale variant
    func convert(_ input: URL, toGrayscaleImage output: URL) throws {
        let arguments = [
            "convert",
            input.path,
            "-set",
            "colorspace",
            "Gray",
            "-separate",
            "-average",
            output.path
        ]

        try runCommand(arguments: arguments)
    }
    
    /// Combine 3 images into a single RGB image.
    func combine(red: ChannelContent, green: ChannelContent, blue: ChannelContent, into output: URL, size requestedSize: MTLSize? = nil) throws {
        let channels = [red, green, blue]
        
        // Collect all urls we touch
        let urls = channels.compactMap { (channel: ChannelContent) -> URL? in
            switch channel {
            case .image(let url):
                return url
            default:
                return nil
            }
        }
        
        // Get the final image size
        var bestSize = MTLSizeMake(0, 0, 0)
        // Only try to find the size when it is not supplied as it is very slow
        if requestedSize == nil {
            bestSize = try findBestSize(images: urls)
        }
        let size = requestedSize ?? bestSize
        
        var arguments: [String] = [
            "convert",
            
            // 8 bit per channel
            "-depth",
            String(size.depth),
            
            // Force image size
            "-size",
            size.resolutionString
        ]
        
        // Configure each channel of the final image
        for channelContent in [red, green, blue] {
            switch channelContent {
            case .image(let url):
                arguments += [
                    "(",
                    // Input
                    url.path,
                    
                    // Force size to match output image size
                    "-resize",
                    size.resolutionString,
                    
                    // Turn to grey otherwise command fails. Images might have grey values but not be in grey format
                    "-set",
                    "colorspace",
                    "Gray",
                    "-separate",
                    "-average", // Use averaging to find greys
                    
                    // Add as channel to next command
                    "+channel",
                    
                    ")"
                ]
            case .color(let value): do {
                let colorString = String(format: "%02X", Int(value * 255))
                arguments += [
                    "(",
                    
                    // Make an image
                    "-size",
                    size.resolutionString,
                    
                    // Fill
                    "xc:#" + colorString + colorString + colorString,
                    
                    // Add as channel to next command
                    "+channel",
                    
                    ")"
                ]
                }
            }
        }
        
        if output.pathExtension == "png" {
            arguments += [
                // To prevent indexed files: https://www.imagemagick.org/Usage/formats/#png_write
                "-define",
                "png:color-type=2"
            ]
        }
        
        arguments += [
            // Make sure we end up in RGB and not Grey
            "-colorspace",
            "sRGB",
            
            // Combine channels
            "-combine",
            output.path
        ]

        try runCommand(arguments: arguments)
    }
}

// MARK: - Sizes

extension TextureTool {
    
    /// Get the size of an image in pixels and depth in bits
    func size(of input: URL) throws -> MTLSize {
        if let known = knownSizes[input] {
            return known
        }

        let arguments = [
            "identify",
            "-format",
            "%[fx:w]\n%[fx:h]\n%z",
            input.path
        ]
        
        guard let result = try runCommand(arguments: arguments) else {
            throw Error.invalidCommandOutput
        }

        let values = result.split(separator: "\n").compactMap { Int($0) }
        guard values.count == 3 else {
            throw Error.invalidCommandOutput
        }

        let size = MTLSizeMake(values[0], values[1], values[2])
        knownSizes[input] = size
        
        return size
    }
    
    /// Find the best size for all images. Currently is the largest fitting.
    private func findBestSize(images: [URL]) throws -> MTLSize {
        try images.map { try size(of: $0) }.reduce(MTLSizeMake(0, 0, 0)) { (memory, size) -> MTLSize in
            MTLSize(width: max(memory.width, size.width),
                    height: max(memory.height, size.height),
                    depth: max(memory.depth, size.depth))
        }
    }
        
    enum ChannelContent {
        case image(URL)
        case color(Float)
    }
}

private extension MTLSize {
    
    /// A string representing the resolution (e.g. 100x100)
    var resolutionString: String {
        return "\(width)x\(height)"
    }
    
}

// Get red channel from RGB image:          convert -channel R -separate ./SparrowEngine/SparrowEngine/Models/grass_albedo.png ./r.png
