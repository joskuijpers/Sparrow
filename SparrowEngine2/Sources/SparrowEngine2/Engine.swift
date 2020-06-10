//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 07/06/2020.
//

import Metal

public protocol EngineApp {
    init(world: World, context: Context) throws
}

public class Context {
    public internal(set) static var shared: Context! = nil
    
    public let graphics: GraphicsContext
    
    init() throws {
        graphics = try GraphicsContext()
    }
}


public class GraphicsContext {
    /**/ public let device: MTLDevice
    /**/ public let library: MTLLibrary
    
    enum Error: Swift.Error {
        /// Could not create a Metal device
        case noDevice
        
        /// Could not load the default library
        case invalidLibrary
    }
    
    init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw Error.noDevice
        }
        
        guard let library = device.makeDefaultLibrary() else {
            throw Error.invalidLibrary
        }
        
        self.device = device
        self.library = library
    }
    
    
//    func make(buffer: BufferDescriptor) -> MTLBuffer {
//
//    }
    
    /// Make a new texture given the descriptor
    func make(texture descriptor: MTLTextureDescriptor) -> MTLTexture? {
        return device.makeTexture(descriptor: descriptor)
    }
    
//    func make(mesh: MeshDescriptor) -> Mesh {
//        
//    }
}



/// Engine root.
public final class Engine {

    public class func create<Class>(_ appClass: Class.Type, options: [Any]) throws -> Class where Class: EngineApp {
        
        let world = World()
        let context = try Context()
        
        // An app will set this as default context
        Context.shared = context
        
        return try appClass.init(world: world, context: context)
    }
    
}
