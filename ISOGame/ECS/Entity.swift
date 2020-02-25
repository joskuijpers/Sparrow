//
//	Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Entity**
///
///  An entity is a general purpose object.
///  It only consists of a unique id (EntityIdentifier).
///  Components can be assigned to an entity to give it behavior or functionality.
///  An entity creates the relationship between all it's assigned components.
public struct Entity {
    @usableFromInline unowned let nexus: Nexus

    /// The unique entity identifier.
    public private(set) var identifier: EntityIdentifier

    internal init(nexus: Nexus, id: EntityIdentifier) {
        self.nexus = nexus
        self.identifier = id
    }
}

// MARK: - Managing components
extension Entity {
    /// Returns the number of components for this entity.
    public var numComponents: Int {
        return nexus.count(components: identifier)
    }

    /// Checks if a component with given type is assigned to this entity.
    /// - Parameter type: the component type.
    public func hasComponent<C>(_ type: C.Type) -> Bool where C: Component {
        return hasComponent(type.identifier)
    }

    /// Checks if a component with a given component identifier is assigned to this entity.
    /// - Parameter compId: the component identifier.
    public func hasComponent(_ compId: ComponentIdentifier) -> Bool {
        return nexus.has(componentId: compId, entityId: identifier)
    }

    /// Checks if this entity has any components.
    public var hasComponents: Bool {
        return nexus.count(components: identifier) > 0
    }

    @discardableResult
    public func add<C>() -> C where C: Component {
        let component = C.init()
        nexus.assign(component: component, to: self)
        return component
    }
    
    /// Add one or more components to this entity.
    /// - Parameter components: one or more components.
    @discardableResult
    public func add(_ components: Component...) -> Entity {
        for component: Component in components {
            add(component)
        }
        return self
    }

    /// Add a component to this entity.
    /// - Parameter component: a component.
//    @discardableResult
//    public func add(component: Component) -> Component {
//        nexus.assign(component: component, to: self)
//        return component
//    }

    /// Add a typed component to this entity.
    /// - Parameter component: the typed component.
    @discardableResult
    public func add<C>(component: C) -> C where C: Component {
        nexus.assign(component: component, to: self)
        return component
    }

    /// Remove a component from this entity.
    /// - Parameter component: the component.
    @discardableResult
    public func removeComponent<C>(_ component: C) -> Entity where C: Component {
        return removeComponent(component.identifier)
    }

    /// Remove a component by type from this entity.
    /// - Parameter compType: the component type.
    @discardableResult
    public func removeComponent<C>(_ compType: C.Type) -> Entity where C: Component {
        return removeComponent(compType.identifier)
    }

    /// Remove a component by id from this entity.
    /// - Parameter compId: the component id.
    @discardableResult
    public func removeComponent(_ compId: ComponentIdentifier) -> Entity {
        nexus.remove(component: compId, from: identifier)
        return self
    }

    /// Remove all components from this entity.
    public func removeAllComponents() {
        nexus.removeAll(componentes: identifier)
    }
    
    @inlinable
    public func get<C>() -> C? where C: Component {
        return nexus.get(for: identifier)
    }

    @inlinable
    public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
        return nexus.get(for: identifier)
    }

    @inlinable
    public func get<A, B>(components _: A.Type, _: B.Type) -> (A?, B?) where A: Component, B: Component {
        let compA: A? = get(component: A.self)
        let compB: B? = get(component: B.self)
        return (compA, compB)
    }

    // swiftlint:disable large_tuple
    @inlinable
    public func get<A, B, C>(components _: A.Type, _: B.Type, _: C.Type) -> (A?, B?, C?) where A: Component, B: Component, C: Component {
        let compA: A? = get(component: A.self)
        let compB: B? = get(component: B.self)
        let compC: C? = get(component: C.self)
        return (compA, compB, compC)
    }
}

// MARK: - Instantiation and destruction
extension Entity {
    /// Instantiate a copy of this game object
    public func instantiate() -> Self {
        let entity = nexus.createEntity()
        
        // Add copies of all components
        // TODO
        
        
        return entity
    }
    
    /// Destroy this entity.
    public func destroy() {
        nexus.destroy(entity: self)
    }

//    /// Add an entity as child.
//    /// - Parameter entity: The child entity.
//    @discardableResult
//    public func addChild(_ entity: Entity) -> Bool {
//        return nexus.addChild(entity, to: self)
//    }
//
//    /// Remove entity as child.
//    /// - Parameter entity: The child entity.
//    @discardableResult
//    public func removeChild(_ entity: Entity) -> Bool {
//        return nexus.removeChild(entity, from: self)
//    }
//
//    /// Removes all children from this entity.
//    public func removeAllChildren() {
//        return nexus.removeAllChildren(from: self)
//    }
//
//    /// Returns the number of children for this entity.
//    public var numChildren: Int {
//        return nexus.numChildren(for: self)
//    }
    
    /// The parent of this entity, if any.
    public var parent: Entity? {
        return nexus.getParent(for: self)
    }
}

// MARK: - Equatable
extension Entity: Equatable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.nexus == rhs.nexus &&
            lhs.identifier == rhs.identifier
    }
}
