//
//  World.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//

import SparrowECS

/// World the game lives in (not gameplay).
///
/// Contains the ECS store. Subclass to add new game functionality such as new systems.
open class World { // Note: note final so games can extend it.
    public internal(set) static var shared: World? = nil

    /// ECS store
    public let nexus: Nexus
    
    /// Graphics context. Use with care.
    public internal(set) var graphics: GraphicsContext!
    
    /// Time information
    @inlinable
    public var time: EngineTimeComponent {
        nexus.single(EngineTimeComponent.self).component
    }
    
    /// Create a new world.
    ///
    /// Initializes the Nexus.
    public required init() {
        nexus = Nexus()
    }

    /// Run a game tick.
    internal func tick(deltaTime: Float) {
        // Update EngineTimeComponent
        time.deltaTime = deltaTime
        time.frameIndex += 1

        // Custom game tick
        update()
        
        // Engine tick
//        print("Update transforms, cameras")
        
        let x = CameraUpdateSystem(world: self)
        x.updateCameras()
    }
    
    /// Update the world. Override this to implement custom functionality.
    ///
    /// This is the place to run systems.
    open func update() {}
    
    
    /// Set the shared world.
    public static func setShared(_ world: World) {
        World.shared = world
    }
}

/// Component that holds engine time.
///
/// Values in this component are only valid within a single frame.
public class EngineTimeComponent: Component, SingleComponent {
    /// Duration of the last frame in seconds.
    public internal(set) var deltaTime: Float = 0
    
    /// Frame number, strictly increasing.
    public internal(set) var frameIndex: UInt64 = 0
    
    // Required for SingleComponent
    public required override init() {}
}
