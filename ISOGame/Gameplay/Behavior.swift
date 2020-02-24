//
//  Behavior.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/**
 A game object behavior. More than one can be assigned to a game object.
 */
class Behavior {
    internal var entityId: EntityIdentifier!
    internal unowned var nexus: Nexus!
    
    /// Called when the behavior starts
    open func onStart() {}
    /// Called on every frame update
    open func onUpdate(deltaTime: TimeInterval) {}
    
    /// The transform component.
    var transform: TransformComponent {
        nexus.get(component: TransformComponent.identifier, for: entityId) as! TransformComponent
    }
    
    /// The entity of this component.
    var entity: Entity {
        return nexus.get(entity: entityId)!
    }
    
    /// Get a sibling component.
    public func get<C>() -> C? where C: Component {
        return nexus.get(for: entityId)
    }

    /// Get a sibling component.
    public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
        return nexus.get(for: entityId)
    }
    
    // todo: instantiate, destroy, add(component:), remove(component:), add(behavior:), remove(behavior:)
}

/**
Component that holds any behavior on the game object.
 */
class BehaviorComponent: Component {
    var behaviors = [Behavior]()
    
    func update(deltaTime: TimeInterval) {
        for behavior in behaviors {
            behavior.onUpdate(deltaTime: deltaTime)
        }
    }
    
    func add(behavior: Behavior) {
        behavior.entityId = entityId
        behavior.nexus = nexus
        behaviors.append(behavior)
    }
}

/**
 System running behavior code.
 */
class BehaviorSystem {
    let nexus: Nexus
    let family: Family<Requires1<BehaviorComponent>>
    
    init(nexus: Nexus) {
        self.nexus = nexus

        /*
         NEXT: see if we can serialize/deserialize this
         
         We will want to serialize the whole Nexus and classes, so we can save Scenes and GameObjects
         To serialize GameObjects (prefabs) we need to be able to save the nexus partially
         
         See if we rename Entity to GameObject
         
         
         */
        family = nexus.family(requires: BehaviorComponent.self)
    }
    
    func update(deltaTime: TimeInterval) {
        for behavior in family {
            behavior.update(deltaTime: deltaTime)
        }
    }
}


extension Entity {
    /// Add a new behavior to the entity.
    ///
    /// Creates a behavior component if it did not exist, and adds the behavior to it.
    func add(behavior: Behavior) {
        var comp: BehaviorComponent? = get()
        if comp == nil {
            comp = BehaviorComponent()
            add(component: comp!)
        }
        
        comp?.add(behavior: behavior)
    }
}
