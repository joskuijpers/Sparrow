//
//  Nexus+Coding.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 15/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowSafeBinaryCoder
import Foundation

extension Nexus {
    
    enum Error: Swift.Error {
        /// The component could not be found in the registry
        case componentNotInRegistry(StableIdentifier)
    }
    
    /// Encode a list of entities and their components.
    public func encode(entities: [Entity]) throws -> Data {
        let registry = Self.storableComponentRegistry
        
        // Create entity mapping
        var entityMapping: [EntityIdentifier: Int] = [:]
        for (index, entity) in entities.enumerated() {
            entityMapping[entity.identifier] = index
        }
        
        // Create list of component storage
        var components: [ComponentStorage] = []
        
        for entity in entities {
            let componentIds = self.get(components: entity.identifier)
            for componentIdentifier in componentIds! {
                let component = self.get(component: componentIdentifier, for: entity.identifier)!
                
                let entityPosition = entityMapping[entity.identifier]!
                
                // Only support storable components that are registered.
                if let storable = component as? NexusStorable,
                    registry[storable.stableIdentifier] != nil {
                    
                    let compStorage = ComponentStorage(entity: entityPosition,
                                                       id: storable.stableIdentifier,
                                                       component: storable)
                    components.append(compStorage)
                }
            }
        }
        
        let container = NexusStorage(numEntities: entities.count,
                                     components: components)
        
        return try SafeBinaryEncoder.encode(container)
    }
    
    /// Decode bytes into entities and components and load them into the nexus.
    public func decode(data: Data) throws -> [Entity] {
        let registry = Self.storableComponentRegistry
        let storage = try SafeBinaryDecoder.decode(NexusStorage.self, data: data)

        // Create entities
        var entityMapping: [Int:Entity] = [:]
        for i in 0..<storage.numEntities {
            let entity = self.createEntity()
            entityMapping[i] = entity
        }
        
        // Create components
        for componentStorage in storage.components {
            let entity = entityMapping[componentStorage.entity]!
            
            guard let componentType = registry[componentStorage.id] else {
                throw Error.componentNotInRegistry(componentStorage.id)
            }

            // We can downcast here because the code that decodes the component also uses the component type.
            // This cast is not strictly neccessary but it makes the program trip if something went wrong.
            let component = unsafeDowncast(componentStorage.component, to: componentType)
            
            entity.add(component: component)
        }

        return Array(entityMapping.values)
    }
}
