//
//  Nexus+SceneGraph.swift
//
//
//  Created by Christian Treffs on 30.09.19.
//

extension Nexus {
    /// Add a child-parent relationship
    @discardableResult
    public final func addChild(_ child: Entity, to parent: Entity) -> Bool {
        let inserted: Bool
        if parentChildrenMap[parent.identifier] == nil {
            parentChildrenMap[parent.identifier] = [child.identifier]
            inserted = true
        } else {
            let (isNewMember, _) = parentChildrenMap[parent.identifier]!.insert(child.identifier)
            inserted = isNewMember
        }
        
        childParentMap[child.identifier] = parent.identifier
        
        if inserted {
            delegate?.nexusEvent(ChildAdded(parent: parent.identifier, child: child.identifier))
        }
        
        return inserted
    }

    /// Remove a child from its parent
    public final func removeChild(_ child: Entity, from parent: Entity) -> Bool {
        return removeChild(child.identifier, from: parent.identifier)
    }

    /// Remove a child from its parent
    @discardableResult
    public final func removeChild(_ child: EntityIdentifier, from parent: EntityIdentifier) -> Bool {
        let removed: Bool = parentChildrenMap[parent]?.remove(child) != nil
        if removed {
            childParentMap.removeValue(forKey: child)
            delegate?.nexusEvent(ChildRemoved(parent: parent, child: child))
        }
        return removed
    }

    /// Remove all children relations for given entity
    public final func removeAllChildren(from parent: Entity) {
        parentChildrenMap[parent.identifier]?.forEach { removeChild($0, from: parent.identifier) }
        return parentChildrenMap[parent.identifier] = nil
    }

    /// Get the number of children for an entity
    public final func numChildren(for entity: Entity) -> Int {
        return parentChildrenMap[entity.identifier]?.count ?? 0
    }
    
    /// Get the parent of an entity, if any.
    public final func getParent(for entity: Entity) -> Entity? {
        if let id = childParentMap[entity.identifier] {
            return get(entity: id)
        }
        return nil
    }
    
    public enum SceneGraphWalkAction {
        case skipChildren, walkChildren
    }
    
    /// Walk the scene graph, depth first, using given visitation function. Return an action in the closure to decide whether to go into the item.
    public final func walkSceneGraph(root: Entity, closure: (_ entity: Entity, _ parent: Entity?) -> SceneGraphWalkAction) {
        // TODO: use stack instead and profile
        func walk(_ e: Entity) {
            parentChildrenMap[e.identifier]?.forEach({ (id) in
                if let entity = get(entity: id), closure(entity, e) == .walkChildren {
                    walk(entity)
                }
            })
        }
        
        if closure(root, nil) == .walkChildren {
            walk(root)
        }
    }
}
