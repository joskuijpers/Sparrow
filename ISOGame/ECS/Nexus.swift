//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    public final weak var delegate: NexusEventDelegate?

    /// Main entity storage.
    /// Entities are tightly packed by EntityIdentifier.
    @usableFromInline final var entityStorage: UnorderedSparseSet<Entity>

    /// - Key: ComponentIdentifier aka component type.
    /// - Value: Array of component instances of same type (uniform).
    ///          New component instances are appended.
    @usableFromInline final var componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>]

    /// - Key: EntityIdentifier aka entity index
    /// - Value: Set of unique component types (ComponentIdentifier).
    ///          Each element is a component identifier associated with this entity.
    @usableFromInline final var componentIdsByEntity: [EntityIdentifier: Set<ComponentIdentifier>]

    /// Entity ids that are currently not used.
    @usableFromInline final var freeEntities: ContiguousArray<EntityIdentifier>

    /// - Key: GroupTraitSet aka component types that make up one distinct Group.
    /// - Value: Tightly packed EntityIdentifiers that represent the association of an entity to the Group.
    @usableFromInline final var groupMembersByTraits: [GroupTraitSet: UnorderedSparseSet<EntityIdentifier>]

    /// - Key: A parent entity id.
    /// - Value: Adjacency Set of all associated children.
    @usableFromInline final var parentChildrenMap: [EntityIdentifier: Set<EntityIdentifier>]
    
    /// - Key: A child entity id.
    /// - Value: The parent entity id.
    @usableFromInline final var childParentMap: [EntityIdentifier: EntityIdentifier]

    public init() {
        entityStorage = UnorderedSparseSet<Entity>()
        componentsByType = [:]
        componentIdsByEntity = [:]
        freeEntities = ContiguousArray<EntityIdentifier>()
        groupMembersByTraits = [:]
        parentChildrenMap = [:]
        childParentMap = [:]
    }

    public final func clear() {
        var iter = entityStorage.makeIterator()
        while let entity = iter.next() {
            destroy(entity: entity)
        }

        entityStorage.removeAll()
        freeEntities.removeAll()

        assert(entityStorage.isEmpty)
        assert(componentsByType.values.reduce(0) { $0 + $1.count } == 0)
        assert(componentIdsByEntity.values.reduce(0) { $0 + $1.count } == 0)
        assert(freeEntities.isEmpty)
        assert(groupMembersByTraits.values.reduce(0) { $0 + $1.count } == 0)

        componentsByType.removeAll()
        componentIdsByEntity.removeAll()
        groupMembersByTraits.removeAll()
        parentChildrenMap.removeAll()
        childParentMap.removeAll()
    }

    deinit {
        clear()
    }
}

// MARK: - Equatable
extension Nexus: Equatable {
    @inlinable
    public static func == (lhs: Nexus, rhs: Nexus) -> Bool {
        return lhs.entityStorage == rhs.entityStorage &&
            lhs.componentIdsByEntity == rhs.componentIdsByEntity &&
            lhs.freeEntities == rhs.freeEntities &&
            lhs.groupMembersByTraits == rhs.groupMembersByTraits &&
            lhs.componentsByType.keys == rhs.componentsByType.keys &&
            lhs.parentChildrenMap == rhs.parentChildrenMap &&
            lhs.childParentMap == rhs.childParentMap
        // NOTE: components are not equatable (yet)
    }
}

// MARK: - CustomDebugStringConvertible
extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<Nexus entities:\(numEntities) components:\(numComponents) groups:\(numGroups)>"
    }
}
