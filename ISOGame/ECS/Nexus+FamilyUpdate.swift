//
//  Nexus+GroupUpdate.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 14.02.19.
//

extension Nexus {
    /// will be called on group init
    final func onGroupInit(traits: GroupTraitSet) {
        guard groupMembersByTraits[traits] == nil else {
            return
        }

        groupMembersByTraits[traits] = UnorderedSparseSet<EntityIdentifier>()
        update(groupMembership: traits)
    }

    final func update(groupMembership traits: GroupTraitSet) {
        // FIXME: iterating all entities is costly for many entities
        var iter = entityStorage.makeIterator()
        while let entity = iter.next() {
            update(membership: traits, for: entity.identifier)
        }
    }

    final func update(groupMembership entityId: EntityIdentifier) {
        // FIXME: iterating all families is costly for many families
        var iter = groupMembersByTraits.keys.makeIterator()
        while let traits = iter.next() {
            update(membership: traits, for: entityId)
        }
    }

    final func update(membership traits: GroupTraitSet, for entityId: EntityIdentifier) {
        guard let componentIds = componentIdsByEntity[entityId] else {
            // no components - so skip
            return
        }

        let isMember: Bool = self.isMember(entity: entityId, inGroupWithTraits: traits)
        if !exists(entity: entityId) && isMember {
            remove(entityWithId: entityId, fromGroupWithTraits: traits)
            return
        }

        let isMatch: Bool = traits.isMatch(components: componentIds)

        switch (isMatch, isMember) {
        case (true, false):
            add(entityWithId: entityId, toGroupWithTraits: traits)
            delegate?.nexusEvent(GroupMemberAdded(member: entityId, toGroup: traits))
            return

        case (false, true):
            remove(entityWithId: entityId, fromGroupWithTraits: traits)
            delegate?.nexusEvent(GroupMemberRemoved(member: entityId, from: traits))
            return

        default:
            return
        }
    }

    final func add(entityWithId entityId: EntityIdentifier, toGroupWithTraits traits: GroupTraitSet) {
        precondition(groupMembersByTraits[traits] != nil)
        groupMembersByTraits[traits].unsafelyUnwrapped.insert(entityId, at: entityId.id)
    }

    final func remove(entityWithId entityId: EntityIdentifier, fromGroupWithTraits traits: GroupTraitSet) {
        precondition(groupMembersByTraits[traits] != nil)
        groupMembersByTraits[traits].unsafelyUnwrapped.remove(at: entityId.id)
    }
}
