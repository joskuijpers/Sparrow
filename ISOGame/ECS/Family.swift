//
//  Family.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

public struct Family<R> where R: FamilyRequirementsManaging {
    @usableFromInline unowned let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(nexus: Nexus, requiresAll: @autoclosure () -> (R.ComponentTypes), excludesAll: [Component.Type]) {
        let required = R(requiresAll())
        self.nexus = nexus
        let traits = FamilyTraitSet(requiresAll: required.componentTypes, excludesAll: excludesAll)
        self.traits = traits
        nexus.onFamilyInit(traits: traits)
    }

    @inlinable public var memberIds: UnorderedSparseSet<EntityIdentifier> {
        return nexus.members(withFamilyTraits: traits)
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
extension Family: Equatable {
    public static func == (lhs: Family<R>, rhs: Family<R>) -> Bool {
        return lhs.nexus == rhs.nexus &&
            lhs.traits == rhs.traits
    }
}

extension Family: Sequence {
    __consuming public func makeIterator() -> ComponentsIterator {
        return ComponentsIterator(family: self)
    }
}

extension Family: LazySequenceProtocol { }

// MARK: - components iterator
extension Family {
    public struct ComponentsIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> R.Components? {
            guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
                return nil
            }

            return R.components(nexus: nexus, entityId: entityId)
        }
    }
}

extension Family.ComponentsIterator: LazySequenceProtocol { }

// MARK: - entity iterator
extension Family {
    @inlinable public var entities: EntityIterator {
        return EntityIterator(family: self)
    }

    public struct EntityIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> Entity? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return nexus.get(unsafeEntity: entityId)
        }
    }
}

extension Family.EntityIterator: LazySequenceProtocol { }

// MARK: - entity component iterator
extension Family {
    @inlinable public var entityAndComponents: EntityComponentIterator {
        return EntityComponentIterator(family: self)
    }

    public struct EntityComponentIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> R.EntityAndComponents? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return R.entityAndComponents(nexus: nexus, entityId: entityId)
        }
    }
}

extension Family.EntityComponentIterator: LazySequenceProtocol { }

// MARK: - relatives iterator

extension Family {
    @inlinable
    public func descendRelatives(from root: Entity) -> RelativesIterator {
        return RelativesIterator(family: self, root: root)
    }

    public struct RelativesIterator: IteratorProtocol {
        @usableFromInline unowned let nexus: Nexus
        @usableFromInline let familyTraits: FamilyTraitSet

        @usableFromInline var relatives: ContiguousArray<(EntityIdentifier, EntityIdentifier)>

        public init(family: Family<R>, root: Entity) {
            self.nexus = family.nexus
            self.familyTraits = family.traits

            // FIXME: this is not the most efficient way to aggregate all parent child tuples
            // Problems:
            // - allocates new memory
            // - needs to be build on every iteration
            // - relies on isMember check
            self.relatives = []
            self.relatives.reserveCapacity(family.memberIds.count)
            aggregateRelativesBreathFirst(root.identifier)
            relatives.reverse()
        }

        mutating func aggregateRelativesBreathFirst(_ parent: EntityIdentifier) {
            guard let children = nexus.parentChildrenMap[parent] else {
                return
            }
            children
                .compactMap { child in
                    guard nexus.isMember(child, in: familyTraits) else {
                        return nil
                    }
                    relatives.append((parent, child))
                    return child
                }
            .forEach { aggregateRelativesBreathFirst($0) }
        }

        public mutating func next() -> R.RelativesDescending? {
            guard let (parentId, childId) = relatives.popLast() else {
                return nil
            }
            return R.relativesDescending(nexus: nexus, parentId: parentId, childId: childId)
        }
    }
}

extension Family.RelativesIterator: LazySequenceProtocol { }
