//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// Component
///
/// A component represents the raw data for one aspect of the object,
/// and how it interacts with the world.
open class Component {
    public init() {}
}

extension Component {
    public static var identifier: ComponentIdentifier { return ComponentIdentifier(Self.self) }
    @inlinable public var identifier: ComponentIdentifier { return Self.identifier }
}
