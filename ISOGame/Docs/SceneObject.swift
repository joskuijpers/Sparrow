//
//  SceneObject.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 14/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import Metal


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

//
//
//class GameObject: Codable {
//    /// The name of the game object.
//    var name: String = ""
//
//    /// The tag of this game object.
//    var tag: String?
//
//    /// Scene that the GameObject is part of.
//    unowned let scene: Scene
//
//    /// Defines whether the GameObject is active in the Scene.
//    var activeInHierarchy: Bool {
////        return activeSelf && parent.activeInHierarchy
//        return false
//    }
//
//    /// List of components of this GameObject.
//    private var components = [Component]()
//
//    /// The local active state of this GameObject.
//    private(set) var activeSelf: Bool = true
//
//    public required init(from decoder: Decoder) throws {
//        self.scene = Scene(screenSize: CGSize.zero)
//    }
//    func encode(to encoder: Encoder) {
//
//    }
//
//    /// Editor only API that specifies if a game object is static.
////    var isStatic: Bool = false
//
//    /// The layer the game object is in.
////    var layer: Int
//
//    var transform: Transform? {
////        self.component<Transform>(type: Transform.self)
//        Transform()
//    }
//
//    init(scene: Scene) {
//        self.scene = scene
//    }
//}
//
//// MARK: - Instantiation and destruction of GameObjects
//
//extension GameObject {
//
////    static func instantiate<T>(original: T) -> T where T: GameObject {
////        return GameObject()
////    }
//
//    /// Removes the GameObject
//    static func destroy(_ object: GameObject) {
//
//    }
//}
//
//// MARK: - Handling GameObject components
//
//extension GameObject {
//    /// Get the component with given type.
//    func component<ComponentType>(ofType componentClass: ComponentType.Type) -> ComponentType? where ComponentType: Component {
//        for component in components {
//            if let c = component as? ComponentType {
//                return c
//            }
//        }
//        return nil
//    }
//
//    /// Get whether a component of given type already exists.
//    func hasComponent<ComponentType>(ofType componentClass: ComponentType.Type) -> Bool where ComponentType: Component {
//        return component(ofType: componentClass) != nil
//    }
//
//    /// Add a new component, if none of such type already exists.
//    func addComponent(_ component: Component) {
////        if !hasComponent(ofType: ) {
////            components.append(component)
////        }
//        components.append(component)
//
//        component.gameObject = self
//        component.didAddToGameObject()
//    }
//
//    /// Remove the given component.
//    func removeComponent<ComponentType>(_ component: ComponentType) where ComponentType: Component {
//
//    }
//
//    /// Remove the component with given type.
//    func removeComponent<ComponentType>(ofType componentClass: ComponentType.Type) where ComponentType: Component {
//
//    }
//
//    /// Remove all components.
//    func removeAllComponents() {
//        components.removeAll()
//    }
//}
//
//// MARK: - Finding other GameObjects
//
//extension GameObject {
//    /// Finds one GameObject by name.
//    func find(name: String) -> GameObject? {
//        return nil
//    }
//
//    /// Finds one active GameObject tagged with tag.
//    func find(tag: String) -> GameObject? {
//        return nil
//    }
//
//    /// Finds all active GameObjects tagged with tag.
//    func findAll(tag: String) -> [GameObject] {
//        return []
//    }
//}
//
//class Component: Codable {
//    public internal(set) weak var gameObject: GameObject?
//    var name: String
//
//    /// The tag of the object.
//    var tag: String? {
//        gameObject?.tag
//    }
//
//    /// The transform of the object
//    var transform: Transform? {
//        gameObject?.transform
//    }
//
//    init() {
//        name = ""
//    }
//}
//
//// MARK: - Finding components
//
//extension Component {
//    // TODO: add the component functions of GameObject here for easier access
//    func component<ComponentType>(ofType componentClass: ComponentType.Type) -> ComponentType? where ComponentType: Component {
//        return gameObject?.component(ofType: componentClass)
//    }
//
//    func didAddToGameObject() {}
//    func willRemoveFromGameObject() {}
//}
//
//class Transform: Component {
//    var position: float3
//    var scale: float3
//    var rotation: float4
//
//    override init() {
//        position = [0, 0, 0]
//        scale = [1, 1, 1]
//        rotation = [0, 0, 0, 1]
//
//        super.init()
//    }
//
//    required init(from decoder: Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//}
//
//class CameraComponent: Component {
//    var fov: Float
//
//    init(fov: Float) {
//        self.fov = fov
//
//        super.init()
//    }
//
//    required init(from decoder: Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//
//
//}
//
//class Behavior: Component {
//    var enabled: Bool = true
//    var isActiveAndEnabled: Bool = true
//
////    override init() {
////
////    }
//
//    func onStart() {}
//    func onUpdate(deltaTime seconds: TimeInterval) {}
//    func onDestroy() {}
//    func onEnabled() {}
//    func onDisable() {}
//}
//
//class MeshComp: Component, Renderable {
//    var meshName: String
//    var mesh: Model
//
//    init(name: String) {
//        self.meshName = name
//        mesh = Model(name: name)
//
//        super.init()
//    }
//
//    required init(from decoder: Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//
//    func render(renderEncoder: MTLRenderCommandEncoder, pass: RenderPass, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms) {
//        mesh.render(renderEncoder: renderEncoder, pass: pass, vertexUniforms: vertexUniforms, fragmentUniforms: fragmentUniforms)
//    }
//}



/*

 TODO
 use the ECS from firebase engine, or copy it
 THIS MIGHT BE POSSIBLE JUST WITH EXTENSIONS ON THE EXISTING ECS PACKAGE, maybe with a SparrowNexus
 What about Codable? Can we create this from a file? save to a file?
 scene.save -> save the nexus, which saves all entities, components, and relationships. Need a way to know which class to use though... can we can the name of a class dynamically? THen we could register them somewhere so go from class -> name, and name -> class.... and then decode/encode.
    nexus.registerComponentType(Transform.self)
        list [String: Component.Type]
        list[type.typeName() : list]
 
    Component protocol {
        static func typeName() -> String { "Transform" }
        static func instantiate() -> Self { return Transform() }
    }
 
 
    Add MeshRenderComponent component
    MeshRenderSystem has render(), which renders all those components, if they are active (or builds the render queue)
 
      Same for PostProcess effects: we can make that too
 
 BehaviorSystem manages all the components with Behavior, which has update(). We can then call behaviorSystem.update(), or .start(), etc.
 Start would need a special trick
    on system.update(), we check if start has run. if not, run start. (so it runs once)
 
 GameObject: Entity {
 
    var name: String {
        return component<Identification>().name
    }
 
     var tag: String {
         return component<Identification>().tag
     }
 
    var scene: Scene {
        return component<Scene,,,>
    }
 
    // can probably do all of this directly in the Nexus, more efficiently
 }
 
 Component {
    var transform: Transform {
        return gameObject.component<Transform>()
    }
    var gameObject: Entity {
        return nexus.... get entity
    }
 }
 
 BehaviorComponent: Component {

 }
 
 main:
 
    behaviorSystem.update()
    RenderSystem.buildQueues
    queues.renderGBuffer
 
 
 
 */






// Scene file


/*
 
 
 {
    objects: [
        {
            name: "My Object",
            isEnabled: true,
            components: [
                {
                    type: "Transform",
                    properties: {
                        position: [1, 0, 0],
                        rotation: [0, 0, 0, 1],
                        scale: [1, 1, 1]
                    }
                },
                {
                    type: "Mesh",
                    properties: {
                        name: "helmet.obj"
                    }
                }
            ]
        }
 
 
    ]
 }
 
 
 
 
 
 
 */


//
//var str = "Hello, playground"
//
//
//protocol Instantiatable: Codable {
//    static var typeName: String { get }
//    static func instantiate() -> Instantiatable
//}
//
//class TestProt: Instantiatable {
//    var test: String
//
//    init() {
//        test = "Hello"
//    }
//
//
//
//    static var typeName: String {
//        "Transform"
//    }
//
//    static func instantiate() -> Instantiatable {
//        TestProt()
//    }
//}
//
//class TestProt2: Instantiatable {
//    var check: String
//
//    init(x: String = "a") {
//        check = x
//    }
//
//
//
//    static var typeName: String {
//        "Transform2"
//    }
//
//    static func instantiate() -> Instantiatable {
//        TestProt2()
//    }
//}
//
//class Nexus {
//    var types = [String: Instantiatable.Type]()
//    var objects = [Instantiatable]()
//
//    func register(_ C: Instantiatable.Type) {
//        let name = C.typeName
//        print("ADDING \(name)")
//
//        types[name] = C
//    }
//
//    func instantiate(_ name: String) -> Instantiatable? {
//        let C = types[name]
//        return C?.instantiate()
//    }
//
//    func add(_ obj: Instantiatable) {
//        objects.append(obj)
//    }
//
//    func encode() -> Data {
//        let encoder = JSONEncoder()
//
//        var data: Data = Data()
//        for obj in objects {
//            let T = type(of: obj)
//            let name = T.typeName
//
//            print("Encode \(name) \(obj)")
//
//            print("[\(name):\(obj)]")
////            let c = Container<T>(typeName: name, value: obj)
////            data = try! encoder.encode(c)
//        }
//
//        return data
//    }
//
//    func decode(_ data: Data) {
//        objects.removeAll()
//
//        let name = "Transform"
//        let ty = types[name]!
//
//        let decoder = JSONDecoder()
//
//        let cont = try! decoder.decode(ty.self, from: data)
//
//        objects.append(cont.value)
//    }
//}
//
//struct Container: Codable where T: Instantiatable {
//    let typeName: String
//    let value: Instantiatable
//
//    enum Keys: CodingKey {
//        case name, value
//    }
//
//    init(typeName: String, value: Instantiatable) {
//        self.typeName = typeName
//        self.value = value
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: Keys.self)
//
//        try container.encode(typeName, forKey: .name)
////        try container.encode(value, forKey: .value)
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: Keys.self)
//        typeName = try container.decode(String.self, forKey: .name)
////        value = try container.decode(TestProt.self, forKey: .value)
//    }
//}
//
//let encoder = JSONEncoder()
//let decoder = JSONDecoder()
//
//let nexus = Nexus()
//nexus.register(TestProt.self)
//
//let input = TestProt()
//input.test = "World"
//
//nexus.add(input)
//nexus.add(TestProt2(x: "Bar"))
//

//        let myInst = Test2()
//        myInst.prop = "hello"
//        let klassName = String(describing: type(of: myInst))
//        
//        let klass: AnyClass = Bundle.main.classNamed(klassName)!
//        let inst = (klass as! Instantiatable.Type).init()
//
//        print(inst)
//        let x = unsafeDowncast(inst, to: Test2.Type)




/*
 
 
 Scene has Octree
 No union AABBs. AABBs rotate (?)
 
 frustrum culling
 
 https://gdbooks.gitbooks.io/legacyopengl/content/Chapter8/halfspace.html
 https://gdbooks.gitbooks.io/3dcollisions/content/Chapter6/frustum.html
 
 
 */
