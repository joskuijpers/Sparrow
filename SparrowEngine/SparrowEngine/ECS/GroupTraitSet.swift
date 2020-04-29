//
//  GroupTraitSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public struct GroupTraitSet {
    public let requiresAll: Set<ComponentIdentifier>
    public let excludesAll: Set<ComponentIdentifier>

    public let setHash: Int

    public init(requiresAll: [Component.Type], excludesAll: [Component.Type]) {
        let requiresAll = Set<ComponentIdentifier>(requiresAll.map { $0.identifier })
        let excludesAll = Set<ComponentIdentifier>(excludesAll.map { $0.identifier })

        precondition(GroupTraitSet.isValid(requiresAll: requiresAll, excludesAll: excludesAll),
                     "invalid Group trait created - requiresAll: \(requiresAll), excludesAll: \(excludesAll)")

        self.requiresAll = requiresAll
        self.excludesAll = excludesAll
        self.setHash = SparrowEngine.hash(combine: [requiresAll, excludesAll])
    }

    // MARK: - match
    @inlinable
    public func isMatch(components: Set<ComponentIdentifier>) -> Bool {
        return hasAll(components) && hasNone(components)
    }

    @inlinable
    public func hasAll(_ components: Set<ComponentIdentifier>) -> Bool {
        return requiresAll.isSubset(of: components)
    }

    @inlinable
    public func hasNone(_ components: Set<ComponentIdentifier>) -> Bool {
        return excludesAll.isDisjoint(with: components)
    }

    // MARK: - valid
    @inlinable
    public static func isValid(requiresAll: Set<ComponentIdentifier>, excludesAll: Set<ComponentIdentifier>) -> Bool {
        return !requiresAll.isEmpty &&
            requiresAll.isDisjoint(with: excludesAll)
    }
}

// MARK: - Equatable
extension GroupTraitSet: Equatable {
    public static func == (lhs: GroupTraitSet, rhs: GroupTraitSet) -> Bool {
        return lhs.setHash == rhs.setHash
    }
}

// MARK: - Hashable
extension GroupTraitSet: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(setHash)
    }
}

extension GroupTraitSet: CustomStringConvertible, CustomDebugStringConvertible {
    @inlinable public var description: String {
        return "<GroupTraitSet [requiresAll:\(requiresAll.description) excludesAll:\(excludesAll.description)]>"
    }

    @inlinable public var debugDescription: String {
        return "<GroupTraitSet [requiresAll:\(requiresAll.debugDescription) excludesAll: \(excludesAll.debugDescription)]>"
    }
}
