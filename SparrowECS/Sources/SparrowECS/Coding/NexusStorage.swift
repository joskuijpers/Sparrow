//
//  NexusStorage.swift
//  SparrowECS
//
//  Created by Jos Kuijpers on 15/06/2020.
//

/// A storage container for one or more entities.
struct NexusStorage: Codable {
    /// Number of entities in this storage.
    var numEntities: Int
    
    /// A list of all components.
    var components: [ComponentStorage]
}
