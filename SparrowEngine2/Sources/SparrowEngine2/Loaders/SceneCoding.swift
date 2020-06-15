//
//  SceneCoding.swift
//  
//
//  Created by Jos Kuijpers on 15/06/2020.
//

import Foundation
import SparrowECS

/// Loader and writier of scene files (.sps).
///
/// Loading results in a hierarchy of entities with components.
/// Entities might have mesh components. These will already be loaded.
public class SceneCoding {

    public init() {}
    
    /// Load the entities from given file into the world.
    ///
    /// - Returns: the entities loaded.
    public func load(from path: URL, into world: World) throws -> [Entity] {
        let data = try Data(contentsOf: path)
        
        let entities = try world.nexus.decode(data: [UInt8](data))

        // Did decode notifications
        for entity in entities {
            for componentIdentifier in world.nexus.get(components: entity.identifier)! {

                if let component = world.nexus.get(component: componentIdentifier, for: entity.identifier),
                    let custom = component as? ComponentStorageDelegate {
                    try custom.didDecode(into: world)
                }
            }
        }
        
        return entities
    }
    
    /// Save given entities to a file.
    public func save(entities: [Entity], in world: World, to path: URL) throws {
        // Will encode notifications
        for entity in entities {
            for componentIdentifier in world.nexus.get(components: entity.identifier)! {
                if let component = world.nexus.get(component: componentIdentifier, for: entity.identifier),
                    let storable = component as? NexusStorable,
                    Nexus.getRegistered(identifier: storable.stableIdentifier) != nil,
                    let custom = storable as? ComponentStorageDelegate {
                    
                    try custom.willEncode(from: world)
                }
            }
        }
        
        let bytes = try world.nexus.encode(entities: entities)
        let data = Data(bytes)
        
        try data.write(to: path)
        
        print("ENCODED \(data)")
    }
    
}
