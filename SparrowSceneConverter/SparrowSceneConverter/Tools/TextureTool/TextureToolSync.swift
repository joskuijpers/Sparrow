//
//  TextureToolSync.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 Synchronous texture tool.
 
 This class is threadsafe.
 */
class TextureToolSync: TextureTool {
    let verbose: Bool
    
    private var knownSizes: [URL:MTLSize] = [:]
    private var knownSizesLock: NSLock // Need lock for async usage

    enum Error: Swift.Error {
        case commandFailed(String)
        
        /// Command have invalid output
        case invalidCommandOutput
    }
    
    required init(verbose: Bool = false) {
        self.verbose = verbose
        self.knownSizesLock = NSLock()
    }
    
    // No waiting needed
    func waitUntilFinished() {}
    
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
    
    /// Write an image to another path, possibly changing format.
    func convert(_ input: URL, to output: URL, allowingAlpha: Bool = true) throws {
        let fileManager = FileManager.default
        
        // Create folders if needed
        try fileManager.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        if fileManager.fileExists(atPath: output.path) {
            try fileManager.removeItem(at: output)
        }
        
        // Fast version assumes files are in the correct format from DCC
        if input.pathExtension == output.pathExtension {
            try fileManager.copyItem(at: input, to: output)
        } else {
            var arguments: [String] = [
                "convert",
                
                input.path
            ]
            
            // TGA behaves oddly causing flipping
            if input.pathExtension == "tga" && output.pathExtension != "tga" {
                arguments += [
                    "-flip"
                ]
            }
            
            if output.pathExtension == "png" {
                let alpha = try (allowingAlpha && hasAlpha(input))
                arguments += [
                    // To prevent indexed files: https://www.imagemagick.org/Usage/formats/#png_write
                    "-define",
                    "png:color-type=" + (alpha ? "6" : "2")
                ]
            }
            
            arguments += [
                output.path
            ]
            
            try runCommand(arguments: arguments)
        }
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
                ]
                
                // TGA behaves oddly causing flipping
                if url.pathExtension == "tga" && output.pathExtension != "tga" {
                    arguments += [
                        "-flip"
                    ]
                }
                
                arguments += [
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
            
            "-orient",
            "bottom-left",
            
            // Combine channels
            "-combine",
            output.path
        ]

        try runCommand(arguments: arguments)
    }

    /// Identify whether the given image has an alpha channel and it is not blank
    private func hasAlpha(_ input: URL) throws -> Bool {
        let arguments = [
            "identify",
            "-format",
            "%A",
            input.path
        ]
        
        guard let result = try runCommand(arguments: arguments) else {
            throw Error.invalidCommandOutput
        }

        // Without Blend there is no alpha channel
        if result != "Blend" {
            return false
        }
        
        let identifyArguments: [String] = [
            "convert",
            input.path,
            
            // Extract alpha channel
            "-alpha",
            "extract",
            
            // Identify format: num unique colors
            "-format",
            "%k",
            
            // Identify
            "-identify",
            "null"
        ]
        
        guard let numColors = try runCommand(arguments: identifyArguments) else {
            throw Error.invalidCommandOutput
        }
        
        return Int(numColors) != 1
    }
    
    /// Get the size of an image in pixels and depth in bits
    private func size(of input: URL) throws -> MTLSize {
        knownSizesLock.lock()
        if let known = knownSizes[input] {
            knownSizesLock.unlock()
            return known
        }
        knownSizesLock.unlock()

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
        
        knownSizesLock.lock()
        knownSizes[input] = size
        knownSizesLock.unlock()
        
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
}

private extension MTLSize {
    
    /// A string representing the resolution (e.g. 100x100)
    var resolutionString: String {
        return "\(width)x\(height)"
    }
    
}
