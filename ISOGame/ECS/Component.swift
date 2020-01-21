//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Component**
///
/// A component represents the raw data for one aspect of the object,
/// and how it interacts with the world.
public class Component {
//    static var identifier: ComponentIdentifier { get }
//    var identifier: ComponentIdentifier { get }
    internal unowned var nexus: Nexus? = nil
    internal var entityId: EntityIdentifier? = nil
    
    func addedToEntity(_ entity: Entity) {
        nexus = entity.nexus
        entityId = entity.identifier
    }
}

extension Component {
    public static var identifier: ComponentIdentifier { return ComponentIdentifier(Self.self) }
    @inlinable public var identifier: ComponentIdentifier { return Self.identifier }
    
    /// The entity of this component.
    var entity: Entity? {
        guard let id = entityId else { return nil }
        return nexus?.get(entity: id)
    }
    
    /// Get a sibling component.
    public func getComponent<C>() -> C? where C: Component {
        if let id = entityId {
            return nexus?.get(for: id)
        }
        return nil
    }

    /// Get a sibling component.
    public func getComponent<A>(component compType: A.Type = A.self) -> A? where A: Component {
        if let id = entityId {
            return nexus?.get(for: id)
        }
        return nil
    }
}

// MARK: - Instantiation and destruction
extension Component {
    
    /// Destroy the entity of this component.
    func destroy() {
        if let id = entityId {
            nexus?.get(entity: id)?.destroy()
        }
    }
}
