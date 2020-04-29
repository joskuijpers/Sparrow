class Light: Component {}
class Camera: Component {}

class Collider: Component {}
class SphereCollider: Collider {}
class BoxCollider: Collider {}

    optional: class MeshSelector {
       var mesh: Mesh, var sharedMesh: Mesh
     }
class Renderer: Component {
    bounds
 }
class MeshRenderer: Renderer {
    var mesh: Mesh
}
class AudioSource: Component {}
class AudioListener: Component {
    update {
        AVListener position = transform.worldPosition
    }
}
 
Renderer.bounds
Collider.bounds
 Mesh.bounds -> using min/max from GLTF


 // Actual mesh stuff (Model)
 class Mesh: Resource {
   bounds
 }
 
 
 // Debug drawing, useful for showing bounds and colliders
 class Gizmos {
    static func drawWireSphere(worldPos, size) {}
    static func drawBox(min, max) {}
 }
 
 
 class Resources {
   static load<T: Resource>(name: String)
 }
 
 

 GameObject.swift // extensions
    .createPrimitive(type)
        entity, transform, mesh, collider
    
 Scene/
    Scene.swift
    SceneManager.swift
        static load(name) (async?, later)
    Transform.swift
 Graphics/
    Mesh: Object -> Was Model
        Mesh.Submesh ?
    Camera      https://github.com/Unity-Technologies/UnityCsReference/blob/5bc2902a12bd9f919e03a60f1f1ffffe5c31204c/Runtime/Export/Camera/Camera.bindings.cs
        type orthographics/perspective
    Light: Component
        type
        buildLightData -> LightData for C++
    RendererComponent
        func render()
    MeshRenderer: RendererComponent
        func render()
    MeshSelector
        var mesh
 Rendering/ ??
    MetalRenderer.swift
 Physics/
    PhysicsWorld.swift
    Collider.swift
    RigidBody.swift
    Joint.swift
 Audio/
    AudioSource
    AudioClip/Sample
    AudioListener
 Utils/
    Bounds.swift
 Input/
    Input.getAxis/getButton/getKey??
    InputBinding system
Resources/
     Resources.swift
    ResourceLoadable interface with static fromResource(Data) throws? -> T?
    TextureLoader.swift

Mesh.bounds
Renderer.bounds (???))

Issues:
- for shadow drawing we need an othographic camera that does culling that way. So camera does not necessarily mean a component.....??? but then it is not really a camera is it... so we can calculate some fast matrices for the light pov, and re-use a culling algorithm with input = matrix, output = bool. Culling.swift -> static func isCulled(matrix, bounds)

CULLING:
- mesh.bounds
then [EntityID:Bounds], built by walking graph (with dirty flags). Then at the end when not-dirty, we have a list of cullboxes for every game object. (this requires tree-walk)
After that we can use it for efficiently walking _again_ with culling. Not sure walking twice is a good idea at all... maybe just cache it? But how to do dirtying without storing it in the nodes?


update loop
    behaviorSystem.update(dt)

    physicsSystem.step(dt)

    renderSystem.updateRendersets()
        go through tree once with stack per render set, use culling, add to sets
        - set: camera
        - set: (VISIBLE) lights with shadows

    renderSystem.render(commandQueue)

    commandQueue.end()



RenderSystem
    let lights = Family<Transform, Light>
    let meshes = Family<Transform, MeshSelector, MeshRenderer>
    
    let camera = scene.camera

    let cameraRenderSet: RenderSet
    let lightRenderSets: [RenderSet](4) -- preallocated


    func updateRendersets()
        for each set
            fillRenderSet(set, camera, root)

    func fillRenderSet(set, camera, root)
        queue is [root]

        while queue is not empty
            element = queue.pop()

            if element is not culled using camera
                set.add(element)
                queue.addAll(element.children
            end
        end


    func render(commandQueue)
        camera transforms

        Shadow pass:
            go over each shadow to render, get render set, do rendering with that pass

        Geometry pass:
            go over each queue, do rendering

        Lighting pass:
            shaders

        etc
        etc







Model space --modelMatrix-> World space --viewMatrix-> cameraCoords --projectionMatrix-> homogenous coords









IMGUI

class DebugUI {
    private static var shared
    
    // Window
    func begin(title: String) {}
    func end() {}
    
    func text(text: String) {
    }
    
    func button(text: String) -> bool {
        drawText
        drawRect
        
        return left mouse pressed and mouse within rect bounds
    }
    
    func radio(active: inout Bool, text: String) -> bool {
    
    }
    
    func checkbox(active: inout Bool, text: String) -> bool {
    
    }
    
    func slider(value: inout Float, min: Float, max: Float)
    
    
    
    on Begin():
        dequeue a window
        or create one
    
    button:
        dequeue button
    
    etc
    
    Can this be done? Does it make sense?
    
    
    
}





## Light culling

- Move Frustum creation to separate compute that only runs after a resize
- AABB culling on top of frustums for tighter culling
- Spotlights (once added)
- Remove buildLight from Light code. Add LightCullSystem that does this instead. (Add LightCullInfo component.)

## ECS
- Add singleton components (Entity with this component)
- Single<>
- World
- Transform has parent -> hierarchy
    - getChildren


Group:
World: Class
    createEntity()
    createEntity(from: Entity)
    setSingleton
    getSingleton
Entity: uint64_t
Component: Protocol
System: Protocol



## ECS


#### Entity identifier
```
public struct EntityIdentifier: Identifiable {
    /// provides 4294967295 unique identifiers since it's constrained to UInt32 - invalid.
    public let id: Int

    public init(_ uint32: UInt32) {
        self.id = Int(uint32)
    }
}
extension EntityIdentifier {
    public static let invalid = EntityIdentifier(.max)
}

extension EntityIdentifier: Equatable { }
extension EntityIdentifier: Hashable { }
extension EntityIdentifier: Codable { }
extension EntityIdentifier: Comparable {
    @inlinable
    public static func < (lhs: EntityIdentifier, rhs: EntityIdentifier) -> Bool {
        return lhs.id < rhs.id
    }
}
```

#### Component identifier
```
public struct ComponentIdentifier: Identifiable {
    /// provides 4294967295 unique identifiers since it's constrained to UInt32 - invalid.
    public let id: Int

    public init(_ uint32: UInt32) {
        self.id = Int(uint32)
    }
}
extension ComponentIdentifier {
    public static let invalid = ComponentIdentifier(.max)
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
extension ComponentIdentifier: Codable { }
extension ComponentIdentifier: Comparable {
    @inlinable
    public static func < (lhs: ComponentIdentifier, rhs: ComponentIdentifier) -> Bool {
        return lhs.id < rhs.id
    }
}
```

#### Entity

```
class Entity {
    entityId: EntityIdentifier
    unowned world: World
    
    
    == { entityId == entityId }
}
```

#### Component

```
protocol Component {
    
}
```

#### World

```
class World {
    
    @usableFromInline final var entityStorage: UnorderedSparseSet<EntityIdentifier>
    
    @usableFromInline final var componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>]
        component for entity = componentsByType[type].get(at: entityId)
    
    @usableFromInline final var componentIdsByEntity: [EntityIdentifier: Set<ComponentIdentifier>]
    
    @usableFromInline final var freeEntities: ContiguousArray<EntityIdentifier>


    createEntity() -> Entity {}
    createEntity(from existingEntity: Entity) {}
    destroyEntity(_ entity: Entity)
}
```


MeshRenderer: Renderer
Renderer:
    localToWorldMatrix (ro)
    worldToLocalMatrix (ro)
    
    renderPriority
    

PhysicsShape (instead of colliders)
    type = box, capsule, sphere, cylinder, plane, convex hull, mesh
    size, center, orientation
    physicsMaterial
PhysicsBody
    motionType : static, dynamic, kinematic
    mass
    linear damping
    angular damping
    initial linear/angular velocities
    gravity factor
    
    in unity this is composed of:
PhysicsCollider, PhysicsVelocity, PhysicsMass, PhysicsDamping, PhysicaGravityFactor, PhysicsCustomData


// UNITY DOTS
protocol ComponentSystem {
    func onUpdate() -> Void
}

protocol JobComponentSystem {
func onUpdate() -> Void -> scheduling of jobs,  Job().schedule()
}

struct TriggerJob: TriggerEventsJob -> TriggerEvent{a, b}

Single<PhysicsSettings>
    gravity float3
    solverIterationCount
    threadCountHint
    simulationType

# UNITY DOTS

PhysicsCollider
PhysicsMass
PhysicsVelocity
PhysicsDamping
RenderBounds
    center + extends (AABB)
WorldRenderBounds
    center + extends (aabb)
LocalToWorld
Rotation
Translation
RenderMesh
    mesh




//// SPONZA NEXT STEPS
- Frustum cull also over submeshes -> Find bounds by iterating over vertices
- Fix PBR math
- Try MSAA
- Submesh sorting
- Proper alphatest/alphablend function constants with material as input -> TODO, finding info
- Proper alphatest depth pipeline
- Debug modes for metallic/normal/albedo/roughness/ao/culling
- Do not keep re-creating the pipeline state for the same setups. It is better to keep the least amount of states



Mesh {
    name
    [vertexBuffers]
    [submeshes]
    bounds -> is bounds of all vertices
}

Submesh {
    indexBuffer
    name
    bounds -> is bounds of all vertices pointed to by index buffer
}


// API
struct Material {
    name -> string = ""
    albedo -> float = (1,1,1)
    metalness -> float = 0
    roughness -> float = 0
    emission -> float3 = (0,0,0)
    
    albedoTexture -> MTLTexture?
    metalnessRoughnessAOTexture -> MTLTexture?
    emissionTexture -> MTLTexture?
    
    ambientOcclusionScale -> float = 1
    transparency -> float = 0
    isDoubleSided -> boolean = false
    cullMode -> CullMode(back front) = back
    writesToDepthBuffer = true
    shader -> Shader
}
-> gpuData (ShaderTextures, MaterialShaderData) (system? getter?)
submesh.setMaterial
encode/decode


// Shader: any float values needed on GPU
MaterialShaderData {
    albedo
    metallic
    roughness
    emission
    ambientOcclusionScale
    transparency
}




struct Shader {
    id: UInt
    vertexFunction -> MTLFunction
    fragmentFunction -> MTLFunction
    
    encode: write function names
    decode: load functions from default lib
}

class ShaderCache {
    [shaders] -> id, never remove an item.
    
    depthOnlyOpaque
    depthOnlyAlphaTest
}
