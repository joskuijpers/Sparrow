//
//  ComponentStorage.swift
//  SparrowECS
//
//  Created by Jos Kuijpers on 15/06/2020.
//

/// A storage container for a component.
struct ComponentStorage {
    /// Index of the entity in the entities list of the storage.
    let entity: Int
    
    /// Stable identifier of the component
    let id: StableIdentifier
    
    /// The component in the storage
    let component: NexusStorable
}

extension ComponentStorage: Codable {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        entity = try container.decode(Int.self)
        id = try container.decode(UInt64.self)
        
        let registry = Nexus.storableComponentRegistry
        let componentType = registry[id]!
        component = try componentType.decode(from: &container)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(entity)
        try container.encode(id)
        
        try component.encode(into: &container)
    }
    
}

extension NexusStorable {
    
    func encode(into container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }
    
    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Self {
        try Self.init(from: container.superDecoder())
    }
    
}
