//
//  Nexus+Group.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    public final var numGroups: Int {
        return groupMembersByTraits.keys.count
    }

    public func canBecomeMember(_ entity: Entity, in traits: GroupTraitSet) -> Bool {
        guard let componentIds = componentIdsByEntity[entity.identifier] else {
            assertionFailure("no component set defined for entity: \(entity)")
            return false
        }
        return traits.isMatch(components: componentIds)
    }

    public func members(withGroupTraits traits: GroupTraitSet) -> UnorderedSparseSet<EntityIdentifier> {
        return groupMembersByTraits[traits] ?? UnorderedSparseSet<EntityIdentifier>()
    }

    public func isMember(_ entity: Entity, in group: GroupTraitSet) -> Bool {
        return isMember(entity.identifier, in: group)
    }

    public func isMember(_ entityId: EntityIdentifier, in group: GroupTraitSet) -> Bool {
        return isMember(entity: entityId, inGroupWithTraits: group)
    }

    public func isMember(entity entityId: EntityIdentifier, inGroupWithTraits traits: GroupTraitSet) -> Bool {
        return members(withGroupTraits: traits).contains(entityId.id)
    }
}
