//
//  Nexus+Coding.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 15/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowSafeBinaryCoder

extension Nexus {
    
    enum Error: Swift.Error {
        /// The component could not be found in the registry
        case componentNotInRegistry(StableIdentifier)
    }
    
    public func encode(registry: [StableIdentifier:NexusStorable.Type], entities: [Entity]) throws -> [UInt8] {
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
                    let encodedComponentData = try SafeBinaryEncoder.encode(storable)
                    
                    let compStorage = ComponentStorage(entity: entityPosition,
                                                       id: storable.stableIdentifier,
                                                       data: encodedComponentData)
                    components.append(compStorage)
                }
            }
        }
        
        let container = NexusStorage(numEntities: entities.count,
                                     components: components)
        
        return try SafeBinaryEncoder.encode(container)
    }
    
    public func decode(registry: [StableIdentifier:NexusStorable.Type], data: [UInt8]) throws -> [Entity] {
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

            // Try to decode the component
            let component = try componentType.init(_data: componentStorage.data)
            
            entity.add(component: component)
        }

        return Array(entityMapping.values)
    }
}


extension Decodable {
    
    /// Decode with some extra typing state.
    fileprivate init(_data: [UInt8]) throws {
        self = try SafeBinaryDecoder.decode(Self.self, data: _data)
    }
}
