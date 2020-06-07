# SparrowEngine2

The Sparrow Game Engine



# for PhysX
https://github.com/bscothern/SwiftyPOSIX/blob/master/Package.swift
http://ankit.im/swift/2016/05/21/creating-objc-cpp-packages-with-swift-package-manager/
https://www.hackingwithswift.com/articles/87/how-to-wrap-a-c-library-in-swift
https://gameworksdocs.nvidia.com/simulation.html

# Folders

```
- Audio/ Sound/??
    - Systems/
    - Components/
        - AudioSource.swift // E.g. on a car 
        - AudioListener.swift // E.g. on the player
        - (AudioState.swift) // Singleton
        
- Graphics/
    - Systems/
        - MeshRenderSystem.swift
        - CameraSystem.swift
        - LightRenderSystem.swift
        // - TextRenderSystem.swift
        // - OverlayRenderSystem.swift
    - Components/
        - Camera.swift
        - RenderMesh.swift
        - Light.swift
        - Transform.swift
        
    - Mesh.swift
    - Submesh.swift
    - Material.swift
    - Texture.swift
    - Shader.swift
    
    - MeshLoader.swift
    - TextureLoader.swift
    
    - RenderQueue.swift
    - VertexDescriptor.swift
    - Primitive.swift
    
- Physics/
    - Systems/
        - PhysicsUpdateStateSystem.swift
    - Components/
        - PhysicsBody.swift
        - PhysicsMover.swift
        - PhysicsJoint.swift
        - PhysicsShape.swift
        
- Math/
    - MathLibrary.swift
    - Frustum.swift
    - Bounds.swift
    
- Scene/
    - SceneManager.swift
    - SceneLoader.swift
    - Scene.swift

- Input/
    - Systems/
        - // system for updating the input state with the OS
    - Components/
        - InputState.swift

- Debug/
        - DebugRendering.swift
```




AssetLoader
   - ?? resource paht handling??
   - res:// as scheme prefix of root of GameResources/ in Bundle
   - Texture might need to be a class instead of a struct... passing it around instead so we know how often it is used

MeshLoader
    - refactor to
    - load .spm
    - change SparrowAsset to SparrowMesh .spm
    
TextureLoader

SceneLoader
    loads .sps

Input
    - refactor to be proper ECS, Single<InputState>
SparrowViewportView
    - no need for refactor, but add mouse capturing support



TODO now:
- Scene is not the way it has to be done.

- SceneManager -> useless
- Where to store current viewport camera?? Single<ViewPortState> .camera .size ?    Viewport (.size, .currentCamera), -> currentViewport?



# Scene/Prefab loading

- List of entities
- List of components, each with reference to entity
- Components have data
- Some special cases, e.g. Mesh will instead write the mesh resource name

- GLTF importing:
    - for each mesh, build a .spm file with their textures
    - for every node, build an Entity with Transform component
    - if the node has a mesh, add RenderMesh component, link to the mesh with resource name
    - if node has a camera, add Camera component
    - if node has a light, add Light component
    
- OBJ importing:
    - convert 1 mesh, build .spm with textures
    - write a prefab with 1 entity, with 1 transform component at 0,0,0 and 1 RenderMesh pointing to the spm
    
- Importer:
    - restructure to split between mesh and prefab. most work is the mesh anyway:
    - collect meshes, unique, -> for mesh, do
    - build nodes, scenes, etc -> for mesh, do
    
- SPM:
    - mesh
    - buffers
    - bufferviews
    - textures
    - materials
    - (subviews)
    - (bounds)
    - (fileHeader)
    -> Remove Camera, Light, Node, Scene
    -> use SPM prefix
    -> SPMFile

- SPS:
    - PrefabFile: -> SPSFile?
    - (fileHeader): generator, version, origin, isPrefab
    - [entities] -> or a 'num entities'
    - [components] -> PrefabComponent
    PrefabComponent { entity: Int, component: ??, HOW TO FIND? }
    -> Use SPS prefix

# Service Locator
https://github.com/skypjack/entt/wiki/Crash-Course:-service-locator

Could use AudioService or PhysicsService as examples. Do we need this? We can probably build it like described in that wiki
Nexus.services.get<T>() -> T? where T: Service (or NullService)
Nexus.services.set<T>(_ service: T) where T : Service



# FIle System
- PhysicsFS
   - Set search directories
      - search in any of these, combines into 1 search
      - support ZIP
   - set write directory -> all new files / written files

# From TheMachinery

- SceneTree component holds a node tree like for skeletons (no need for an entity )
- Tag: to add hashed tag for finding entities in World (1 or more)

- Link system and child entity system is different? (Need to try in the editor)
- Owner component allows an entity to be owned by another -> separate from sscenegraph. We can use this for assets/prefabs. When parent is destructed, so are children
    - component has list of chidlren IDs
    - function to get children [entities]
    - function to add children
    - function to remove children
    - function to remove all children
    - 

### Physics
- Physics Body
- Physics Joint
- Physics Mover (CCT)
- Physics Shape: if has body, dynamic, else, static
- 'Render' or 'RenderMesh': will cause rendering

Assets: Physics Material (friction, restitution), Physics Collision (class to determine what collides with what)

# ImGUI
https://github.com/Green-Sky/imgui_entt_entity_editor
- ComponentEditorWidget: protocol EditorWidget
- extend a component with this, implement the present() function, call a bunch of imgui stuff.
- when selected in editor, for each component: show header. if is EditorWidget, call that function too to add widgets

```
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
```





# Older stuff

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

