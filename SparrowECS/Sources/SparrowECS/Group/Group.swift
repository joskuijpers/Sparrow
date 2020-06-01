//
//  Group.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

public struct Group<R> where R: GroupRequirementsManaging {
    @usableFromInline unowned let nexus: Nexus
    public let traits: GroupTraitSet

    public init(nexus: Nexus, requiresAll: @autoclosure () -> (R.ComponentTypes), excludesAll: [Component.Type]) {
        let required = R(requiresAll())
        self.nexus = nexus
        let traits = GroupTraitSet(requiresAll: required.componentTypes, excludesAll: excludesAll)
        self.traits = traits
        nexus.onGroupInit(traits: traits)
    }

    @inlinable public var memberIds: UnorderedSparseSet<EntityIdentifier> {
        return nexus.members(withGroupTraits: traits)
    }

    @inlinable public var count: Int {
        return memberIds.count
    }

    @inlinable public var isEmpty: Bool {
        return memberIds.isEmpty
    }

    @inlinable
    public func canBecomeMember(_ entity: Entity) -> Bool {
        return nexus.canBecomeMember(entity, in: traits)
    }

    @inlinable
    public func isMember(_ entity: Entity) -> Bool {
        return nexus.isMember(entity, in: traits)
    }
}

// MARK: - Equatable
extension Group: Equatable {
    public static func == (lhs: Group<R>, rhs: Group<R>) -> Bool {
        return lhs.nexus == rhs.nexus &&
            lhs.traits == rhs.traits
    }
}

extension Group: Sequence {
    __consuming public func makeIterator() -> ComponentsIterator {
        return ComponentsIterator(group: self)
    }
}

extension Group: LazySequenceProtocol { }

// MARK: - components iterator
extension Group {
    public struct ComponentsIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(group: Group<R>) {
            self.nexus = group.nexus
            memberIdsIterator = group.memberIds.makeIterator()
        }

        public mutating func next() -> R.Components? {
            guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
                return nil
            }

            return R.components(nexus: nexus, entityId: entityId)
        }
    }
}

extension Group.ComponentsIterator: LazySequenceProtocol { }

// MARK: - entity iterator
extension Group {
    @inlinable public var entities: EntityIterator {
        return EntityIterator(group: self)
    }

    public struct EntityIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(group: Group<R>) {
            self.nexus = group.nexus
            memberIdsIterator = group.memberIds.makeIterator()
        }

        public mutating func next() -> Entity? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return nexus.get(unsafeEntity: entityId)
        }
    }
}

extension Group.EntityIterator: LazySequenceProtocol { }

// MARK: - entity component iterator
extension Group {
    @inlinable public var entityAndComponents: EntityComponentIterator {
        return EntityComponentIterator(group: self)
    }

    public struct EntityComponentIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(group: Group<R>) {
            self.nexus = group.nexus
            memberIdsIterator = group.memberIds.makeIterator()
        }

        public mutating func next() -> R.EntityAndComponents? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return R.entityAndComponents(nexus: nexus, entityId: entityId)
        }
    }
}

extension Group.EntityComponentIterator: LazySequenceProtocol { }

