//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 07/06/2020.
//

/// Engine startup.
///
/// Allows configurating and starting the engine.
public final class Engine {
    
    public enum Option {
    }

    public class func create<WorldClass>(_ worldClass: WorldClass.Type, options: [Option] = []) -> WorldClass where WorldClass: World {
        let world = worldClass.init()
        
        // An app will set this as default context
        World.setShared(world)
        
        return world
    }
    
}
