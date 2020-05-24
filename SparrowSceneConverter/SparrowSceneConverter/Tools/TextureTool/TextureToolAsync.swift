//
//  TextureToolAsync.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/// Async texture tool. Delays conversion and combining to the background thread.
class TextureToolAsync: TextureTool {
    private let jobQueue: JobQueue<TextureJobInput, Error>
    
    required init(verbose: Bool) {
        let jobRunner = TextureJobRunner()
        jobQueue = JobQueue<TextureJobInput, Error>(runner: jobRunner)
    }
    
    func waitUntilFinished() {
        let errors = jobQueue.waitUntilFinished().compactMap { $0 }
        
        print("FINISHED WITH ERRORS \(errors)")
    }
    
    func convert(_ input: URL, toGrayscaleImage output: URL) throws {
        jobQueue.enqueue(input: TextureJobInput(action: .convertGrayscale(input, output)))
    }
    
    func convert(_ input: URL, to output: URL, allowingAlpha: Bool = true) throws {
        jobQueue.enqueue(input: TextureJobInput(action: .convert(input, output, allowingAlpha)))
    }
    
    func combine(red: ChannelContent, green: ChannelContent, blue: ChannelContent, into output: URL, size requestedSize: MTLSize? = nil) throws {
        jobQueue.enqueue(input: TextureJobInput(action: .combineChannels(red, green, blue, output, requestedSize)))
    }
}

private struct TextureJobInput {
    let action: Action
    
    enum Action {
        case convertGrayscale(URL, URL)
        case convert(URL, URL, Bool)
        case combineChannels(ChannelContent, ChannelContent, ChannelContent, URL, MTLSize?)
    }
}

private class TextureJobRunner: JobRunner<TextureJobInput, Error> {
    let textureTool: TextureTool
    
    override init() {
        self.textureTool = TextureToolSync(verbose: false)
        
        super.init()
    }
    
    /// Clone this runner into a new thread
    override func clone(thread: Thread) -> Self? {
        print("CLONE RUNNER")
        
        return self
    }
    
    override func run(_ job: Job<TextureJobInput>) -> Error? {
        print("RUN JOB \(job.input)")
        
        do {
            switch job.input.action {
                case .convertGrayscale(let input, let output):
                    try textureTool.convert(input, toGrayscaleImage: output)
                case .convert(let input, let output, let allowingAlpha):
                    try textureTool.convert(input, to: output, allowingAlpha: allowingAlpha)
                case .combineChannels(let red, let green, let blue, let output, let size):
                    try textureTool.combine(red: red, green: green, blue: blue, into: output, size: size)
            }
            
            // No error
            return nil
        } catch {
            return error
        }
    }
}
