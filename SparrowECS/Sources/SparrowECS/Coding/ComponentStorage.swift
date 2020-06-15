//
//  ComponentStorage.swift
//  SparrowECS
//
//  Created by Jos Kuijpers on 15/06/2020.
//

/// A storage container for a component.
struct ComponentStorage: Codable {
    /// Index of the entity in the entities list of the storage.
    var entity: Int
    
    /// Stable identifier of the component
    var id: StableIdentifier
    
    /// Data of the component, encoded.
    var data: [UInt8]
}
