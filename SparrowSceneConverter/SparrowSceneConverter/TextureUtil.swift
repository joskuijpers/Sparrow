//
//  TextureTools.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 23/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

struct TextureUtil {
    
    enum Error: Swift.Error {
        case commandFailed(String)
        
        /// Command have invalid output
        case invalidCommandOutput
    }
    
    @discardableResult
    static func runCommand(arguments: [String]) throws -> String? {
        let task = Process()
        
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/magick")
        task.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        print("ARGS \(task.arguments)")
        
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
    static func convert(_ input: URL, toGrayscaleImage output: URL) throws {
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

        try Self.runCommand(arguments: arguments)
    }
    
    /// Get the size of an image in pixels and depth in bits
    static func size(of input: URL) throws -> MTLSize {
        let arguments = [
            "identify",
            "-format",
            "%[fx:w]\n%[fx:h]\n%z",
            input.path
        ]
        
        guard let result = try Self.runCommand(arguments: arguments) else {
            throw Error.invalidCommandOutput
        }

        let size = result.split(separator: "\n").compactMap { Int($0) }
        
        guard size.count == 3 else {
            throw Error.invalidCommandOutput
        }

        return MTLSizeMake(size[0], size[1], size[2])
    }
    
    /// Combine 3 images into a single RGB image.
    static func combine(red: ChannelContent, green: ChannelContent, blue: ChannelContent, into output: URL, size: MTLSize) throws {
        var arguments: [String] = [
            "convert",
            
            // 8 bit per channel
            "-depth",
            String(size.depth),
            
            // Force image size
            "-size",
            size.resolutionString
        ]
        
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
            case .black:
                arguments += [
                    "(",
                    
                    // Make an image
                    "-size",
                    size.resolutionString,
                    
                    // Fill
                    "xc:black",
                    
                    // Add as channel to next command
                    "+channel",
                    
                    ")"
                ]
            case .white:
                arguments += [
                    "(",
                    
                    // Make an image
                    "-size",
                    size.resolutionString,
                    
                    // Fill
                    "xc:white",
                    
                    // Add as channel to next command
                    "+channel",
                    
                    ")"
                ]
            }
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
    
    enum ChannelContent {
        case image(URL)
        case black
        case white
    }
}

private extension MTLSize {
    
    /// A string representing the resolution (e.g. 100x100)
    var resolutionString: String {
        return "\(width)x\(height)"
    }
    
}

// Get red channel from RGB image:          convert -channel R -separate ./SparrowEngine/SparrowEngine/Models/grass_albedo.png ./r.png

//convert  rose: -fx R channel_red.gif
//convert  rose: -fx G channel_green.gif
//convert  rose: -fx B channel_blue.gif
