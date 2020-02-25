//
//	NexusEvents.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol NexusEvent {}

public struct EntityCreated: NexusEvent {
    public let entityId: EntityIdentifier
}

public struct EntityDestroyed: NexusEvent {
    public let entityId: EntityIdentifier
}

public struct ComponentAdded: NexusEvent {
    public let component: ComponentIdentifier
    public let toEntity: EntityIdentifier
}

public struct ComponentUpdated: NexusEvent {
    public let atEnity: EntityIdentifier
}

public struct ComponentRemoved: NexusEvent {
    public let component: ComponentIdentifier
    public let from: EntityIdentifier
}

public struct GroupMemberAdded: NexusEvent {
    public let member: EntityIdentifier
    public let toGroup: GroupTraitSet
}

public struct GroupMemberRemoved: NexusEvent {
    public let member: EntityIdentifier
    public let from: GroupTraitSet
}

public struct GroupCreated: NexusEvent {
    public let group: GroupTraitSet
}

public struct GroupDestroyed: NexusEvent {
    public let group: GroupTraitSet
}

public struct ChildAdded: NexusEvent {
    public let parent: EntityIdentifier
    public let child: EntityIdentifier
}

public struct ChildRemoved: NexusEvent {
    public let parent: EntityIdentifier
    public let child: EntityIdentifier
}
