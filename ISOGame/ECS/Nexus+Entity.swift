//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    @inlinable
    internal func nextEntityId() -> EntityIdentifier {
        guard let nextReused: EntityIdentifier = freeEntities.popLast() else {
            return EntityIdentifier(UInt32(entityStorage.count))
        }
        return nextReused
    }

    @discardableResult
    public func createEntity() -> Entity {
        let newEntityIdentifier: EntityIdentifier = nextEntityId()
        let newEntity = Entity(nexus: self, id: newEntityIdentifier)
        entityStorage.insert(newEntity, at: newEntityIdentifier.id)
        delegate?.nexusEvent(EntityCreated(entityId: newEntityIdentifier))
        return newEntity
    }

    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        let newEntity = createEntity()
        components.forEach { newEntity.add(component: $0) }
        return newEntity
    }

    /// Number of entities in nexus.
    public var numEntities: Int {
        return entityStorage.count
    }

    /// Get whether an entity with given ID exists
    public func exists(entity entityId: EntityIdentifier) -> Bool {
        return entityStorage.contains(entityId.id)
    }

    /// Get the entity with given ID
    public func get(entity entityId: EntityIdentifier) -> Entity? {
        return entityStorage.get(at: entityId.id)
    }

    /// Get the entity with given ID
    public func get(unsafeEntity entityId: EntityIdentifier) -> Entity {
        return entityStorage.get(unsafeAt: entityId.id)
    }

    /// Destroy given entity. The entity object is not valid after this call.
    @discardableResult
    public func destroy(entity: Entity) -> Bool {
        let entityId: EntityIdentifier = entity.identifier

        guard entityStorage.remove(at: entityId.id) != nil else {
            delegate?.nexusNonFatalError("EntityRemove failure: no entity \(entityId) to remove")
            return false
        }

        removeAllChildren(from: entity)

        if removeAll(componentes: entityId) {
            update(groupMembership: entityId)
        }

        freeEntities.append(entityId)

        delegate?.nexusEvent(EntityDestroyed(entityId: entityId))
        return true
    }
}
