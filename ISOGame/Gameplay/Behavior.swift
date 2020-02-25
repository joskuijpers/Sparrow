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
    fileprivate var entityId: EntityIdentifier!
    private unowned var nexus = Nexus.shared()
    
    /// Called when the behavior starts
    open func onStart() {}
    /// Called on every frame update
    open func onUpdate(deltaTime: TimeInterval) {}
    
    /// The transform component.
    var transform: Transform? {
        nexus.get(component: Transform.identifier, for: entityId) as? Transform
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
    
    // instantiate
    //   create new entity
    //      instantiate every component -> is an init + copy values!
}

/**
Component that holds any behavior on the game object.
 */
fileprivate class BehaviorComponent: Component {
    private var behaviors = [Behavior]()
    
    func update(deltaTime: TimeInterval) {
        for behavior in behaviors {
            behavior.onUpdate(deltaTime: deltaTime)
        }
    }
    
    func add(behavior: Behavior) {
        behavior.entityId = entityId
        behaviors.append(behavior)
    }
    
    func remove(behavior: Behavior) {
        behavior.entityId = nil
//        behaviors.removeAll { (search) -> Bool in
//            return search == behavior
//        }
    }
}

/**
 System running behavior code.
 */
class BehaviorSystem {
    private let behaviors = Nexus.shared().group(requires: BehaviorComponent.self)
    
    func update(deltaTime: TimeInterval) {
        for behavior in behaviors {
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
