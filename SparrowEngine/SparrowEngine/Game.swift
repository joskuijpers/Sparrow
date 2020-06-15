//
//  Game.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 11/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine2

import SparrowECS
import SparrowSafeBinaryCoder

/// Testgame!
class GameWorld: World {
    var renderer: MetalRenderer!
    
    // Systems
    var playerCameraSystem: PlayerCameraSystem!
    var rotatingSystem: RotatingSystem!
    
    func initialize(view: SparrowMetalView) throws {
        // Create renderer. Also creates devices needed for loading GPU assets
        renderer = try MetalRenderer(for: view)
        try renderer.load(world: self)
        
        // Create initial entities
        loadScene()
        
        // Create systems
        playerCameraSystem = PlayerCameraSystem(world: self)
        rotatingSystem = RotatingSystem(world: self)
        
        
        let myTest = nexus.createEntity()
        myTest.add(component: Transform())

        // Register of stable IDs
        var componentRegister: [StableIdentifier:NexusStorable.Type] = [:]
        componentRegister[Camera.stableIdentifier] = Camera.self
        componentRegister[Transform.stableIdentifier] = Transform.self
        
        do {
            let data = try testEncoding(registry: componentRegister, entities: [camera!, myTest])
            let outputEntities = try testDecoding(registry: componentRegister, data: data)
            
            print("DECODED \(outputEntities)")
        } catch {
            print("ERROR \(error)")
        }
        
        exit(0)
    }
    
    private func loadScene() {
        // Load a model
        //        let sponza = try! loadModel("sponza.sps")
        
        // Create camera
        let camera = nexus.createEntity()
        let t = camera.add(component: Transform())
//        t.localPosition = [0, 0, 2]
        t.localPosition = [-12.5, 1.4, -0.5]
        t.eulerAngles = [0, Float(90.0).degreesToRadians, 0]
        camera.add(component: Camera())
        
        self.camera = camera
        
        //        scene.camera = cameraComp
        
        let skyLight = nexus.createEntity()
        let tlight = skyLight.add(component: Transform())
        tlight.rotation = simd_quatf(angle: Float(70).degreesToRadians, axis: [1, 0, 0])
        let light = skyLight.add(component: Light(type: .directional))
        light.color = float3(1, 1, 1)

        
        let device = self.graphics.device
        let textureLoader = TextureLoader(device: device)
        let meshLoader = MeshLoader(device: device, textureLoader: textureLoader)

        let objMesh = try! meshLoader.load(name: "ironSphere/ironSphere.spm")

        for x in -10..<10 {
            for z in -10..<10 {
                let obj = nexus.createEntity()
                let t = obj.add(component: Transform())
                t.position = [Float(x) * 3, 0, Float(z) * 3]
                obj.add(component: RenderMesh(mesh: objMesh))
                obj.add(component: RotationSpeed(seed: 22 * x + z))
            }
        }
        
    }
    
    override func update() {
        playerCameraSystem.update(world: self)
        rotatingSystem.update(world: self)
    }
    
    
    
    
    
    
    
    func testEncoding(registry: [StableIdentifier:NexusStorable.Type], entities: [Entity]) throws -> [UInt8] {
        // Create entity mapping
        var entityMapping: [EntityIdentifier: Int] = [:]
        for (index, entity) in entities.enumerated() {
            entityMapping[entity.identifier] = index
        }
        
        // Create list of component storage
        var components: [ComponentStorage] = []
        
        for entity in entities {
            let componentIds = nexus.get(components: entity.identifier)
            for componentIdentifier in componentIds! {
                let component = nexus.get(component: componentIdentifier, for: entity.identifier)!
                
                let entityPosition = entityMapping[entity.identifier]!
                
                // Only support storable components that are registered.
                if let storable = component as? NexusStorable,
                    registry[storable.stableIdentifier] != nil {
                    let encodedComponentData = try SafeBinaryEncoder.encode(storable)
                    
                    let compStorage = ComponentStorage(entity: entityPosition,
                                                       id: storable.stableIdentifier,
                                                       data: encodedComponentData)
                    components.append(compStorage)
                }
            }
        }
        
        let container = NexusStorage(numEntities: entities.count,
                                     components: components)
        
        return try SafeBinaryEncoder.encode(container)
    }
    
    func testDecoding(registry: [StableIdentifier:NexusStorable.Type], data: [UInt8]) throws -> [Entity] {
        let storage = try SafeBinaryDecoder.decode(NexusStorage.self, data: data)

        // Create entities
        var entityMapping: [Int:Entity] = [:]
        for i in 0..<storage.numEntities {
            let entity = nexus.createEntity()
            entityMapping[i] = entity
        }
        
        // Create components
        for componentStorage in storage.components {
            let entity = entityMapping[componentStorage.entity]!
            
            guard let componentType = registry[componentStorage.id] else {
                fatalError("Component does not exist (anymore)")
            }

            // Try to decode the component
            let component = try componentType.init(_data: componentStorage.data)
            
            entity.add(component: component)
        }

        return Array(entityMapping.values)
    }
}

extension Decodable {
    
    /// Decode with some extra typing state.
    fileprivate init(_data: [UInt8]) throws {
        self = try SafeBinaryDecoder.decode(Self.self, data: _data)
    }
}

/// An identifier that survives restarts, reloads, rebuilds and versions.
typealias StableIdentifier = UInt64

/// A component that can be stored.
///
/// Requires Codable conformance so it can be encoded/decoded.
protocol NexusStorable: Component, Codable {
    /// An identifier that is consistent across restarts, rebuilds, and application versions.
    ///
    /// Used for encoding and decoding.
    static var stableIdentifier: StableIdentifier { get }
    
    /// An identifier that is consistent across restarts, rebuilds, and application versions.
    ///
    /// Used for encoding and decoding. Already implemented
    var stableIdentifier: StableIdentifier { get }
}

extension NexusStorable {
    
    // Implementation of instance identifier, returning type identifier.
    var stableIdentifier: StableIdentifier {
        Self.stableIdentifier
    }
}

/// A storage container for a component.
struct ComponentStorage: Codable {
    /// Index of the entity in the entities list of the storage.
    var entity: Int
    
    /// Stable identifier of the component
    var id: StableIdentifier
    
    /// Data of the component, encoded.
    var data: [UInt8]
}

/// A storage container for one or more entities.
struct NexusStorage: Codable {
    /// Number of entities in this storage.
    var numEntities: Int
    
    /// A list of all components.
    var components: [ComponentStorage]
}



extension Camera: NexusStorable {
    static var stableIdentifier: StableIdentifier {
        return 10
    }
}


extension Transform: NexusStorable {
    static var stableIdentifier: StableIdentifier {
        return 11
    }
}
