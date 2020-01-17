//
//  SceneObject.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 14/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation



/*
 
 Scene
    var rootObjects: [GameObject]
    var objects: [GameObject] // all objects?
 
    init()
    init(fileNamed:)
 
 GameObject (Entity)
    var components: [Component]
    var transform: Transform {
        component(Transform.class)
    }
    .name
    .tag
    func addComponent<ComponentType>(ofType: ComponentType.Type) -> ComponentType?
    // or
    func addComponent(component: Component), after RigidBody(.....)
 
    func component<ComponentType>(ofType: ComponentType.Type) -> ComponentType?
    func removeComponent<ComponentType>(ofType: ComponentType.Type)
 
 
    static find(name: "") -> GameObject?
    static find(tag: "") -> [GameObject]
 
 class Component
    weak var gameObject: GameObject?
    var name: String
 
    func onUpdate()
    func onStart()
    func onAwake()
    func .....
 
    Transform
        weak parent
        children
        siblingIndex ?? computed ??
        root { get parents until parent is nil }
        
        translation/rot/scale
        localMatrix {get}
        worldMatrix {get}
    Light
        or
        PointLight
        DirectionalLight
        SpotLight
    Camera
 
    MeshFilter -> .mesh -> not actually used, so can just put this .mesh in MeshRenderer. (TextMesh is case without Filter). Or call it MeshProvider\
    MeshRenderer -> takes .mesh from Filter
    RigidBody
 
 // GeometryComponent (GK)
 // ParticleComponent (GK)
 
    Behavior
        .enabled
 
 
 
    
 
 ComponentSystem
    // handles all instances of a specific component. How to use this? What does Unity do? Can we still extend existing entities with new components?
    // this way all transforms can update before the mesh renderer. ???? needed???
 
 let obj = SceneObject()
 let light = obj.addComponent<Light>() ???? or addComponent(Light.class)
 light.color = [1, 0, 0]
 
 let light = obj.component(Light.class) ?
 
 
 EntityManager (see Apple GameplayKit)
 
 SceneManager
    activeScene
    scenes
    setActiveScene
 
 Mesh
    Submeshes (?)
    always vertex colors, uv1, normals, position
    always indexed
 
 Material
 
 Texture
 
 RenderQueue
    .background
    .geometry
    .alphaTest
    .geometryLast
    .transparent -> sort back to front
    .overlay

 RenderPass
    .gbuffer
    .shadow
 
 
 Time
    static delta

 Graphics
    func drawMesh() ???
 */
