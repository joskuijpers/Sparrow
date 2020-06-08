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
    public let graphics: GraphicsContext
    
    init() throws {
        graphics = try GraphicsContext()
    }
}


public class GraphicsContext {
    let device: MTLDevice
    
    enum Error: Swift.Error {
        /// Could not create a Metal device
        case noDevice
    }
    
    init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw Error.noDevice
        }
        
        self.device = device
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
        
        return try appClass.init(world: world, context: context)
    }
    
}
