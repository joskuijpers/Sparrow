//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 09/06/2020.
//

import MetalKit

/// Metal backed renderer.
///
/// Creates pipelines, render textures, and everything else needed to render an empty frame.
///
public final class MetalRenderer {
    private let context: GraphicsContext
    private let view: SparrowMetalView
    
    private var delegate: MetalRendererDelegate?
    
    public init(for view: SparrowMetalView) throws {
        context = try GraphicsContext()

        self.view = view
    }
    
    public func load(world: World) throws {
        world.graphics = context
        
        delegate = MetalRendererDelegate(renderer: self, world: world)
        view.delegate = delegate
        view.device = context.device
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 1
        view.clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
        
        // Create the state by calling the state functions
        
        viewSizeChanged(to: view.frame.size)
    }
}

// MARK: - Adjusting the rendering process

extension MetalRenderer {
    
    // set/get debug options
        // albedo/normals/metal/rough/ao
        // wireframe
    
    
    func viewSizeChanged(to size: CGSize) {
        print("viewSizeChanged(\(size)")
    }
}

// MARK: - Creating GPU state

extension MetalRenderer {
    // Building state
}

// MARK: - Rendering a frame

extension MetalRenderer {

    /// Render a single frame
    fileprivate func renderFrame(world: World) {
        let time = world.time
        
        print("renderFrame \(time.frameIndex)")
    }
}


/// Delegate class.
///
/// A separate class because it has to subclass NSObject which causes a costly ObjC bridge.
/// Any screen size changes are forwarded to the renderer. A game tick is instead forwarded
/// to the game first, then is rendered after.
private final class MetalRendererDelegate: NSObject, MTKViewDelegate {
    private unowned let renderer: MetalRenderer
    private unowned let world: World
    
    var lastFrameTime: CFAbsoluteTime!
    
    /// Creates a new renderer delegate
    init(renderer: MetalRenderer, world: World) {
        self.renderer = renderer
        self.world = world
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.viewSizeChanged(to: size)
    }
    
    func draw(in view: MTKView) {
        // Calculate the frame duration for normalizing animations and gameplay.
        if lastFrameTime == nil {
            lastFrameTime = CFAbsoluteTimeGetCurrent() - 1.0 / Double(view.preferredFramesPerSecond)
        }
        let currentTime = CFAbsoluteTimeGetCurrent()

        let deltaTime = Float(currentTime - lastFrameTime)
        lastFrameTime = currentTime
        
        world.tick(deltaTime: deltaTime)
        
        renderer.renderFrame(world: world)
    }
}

/// Graphics context for Metal.
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

    /// Make a new texture given the descriptor
    func make(texture descriptor: MTLTextureDescriptor) -> MTLTexture? {
        return device.makeTexture(descriptor: descriptor)
    }
}
