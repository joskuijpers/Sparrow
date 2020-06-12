//
//  LightSystem.swift
//  
//
//  Created by Jos Kuijpers on 08/06/2020.
//

import SparrowECS
import Metal

/// System for handling lights
public final class LightSystem {
    private let lights: Group<Requires2<Transform, Light>>
    
    public init(world: World) {
        lights = world.nexus.group(requiresAll: Transform.self, Light.self)
    }
    
    public func updateLightBuffer(device: MTLDevice, buffer: inout MTLBuffer!, lightsCount: inout UInt) {
        lightsCount = UInt(lights.count)
        
        // Reallocate if needed
        // TODO: proper sizing with spare-size (blocks), and down sizing. Maybe some ManagedMTLBuffer class?
        let bufferSizeRequired = lights.count * MemoryLayout<ShaderLightData>.stride
        if buffer == nil || buffer.allocatedSize < bufferSizeRequired {
            buffer = device.makeBuffer(length: bufferSizeRequired, options: .storageModeShared)
        }

        for (index, (transform, light)) in lights.enumerated() {
            let ptr = buffer.contents().advanced(by: index * MemoryLayout<ShaderLightData>.stride)
            let lightPtr = ptr.assumingMemoryBound(to: ShaderLightData.self)
            
            switch (light.type) {
            case .directional:
                lightPtr.pointee.type = LightTypeDirectional
                lightPtr.pointee.color = light.color
                lightPtr.pointee.position = transform.forward
                lightPtr.pointee.range = Float.infinity
            case .point:
                lightPtr.pointee.type = LightTypePoint
                lightPtr.pointee.color = light.color
                lightPtr.pointee.position = transform.position
                lightPtr.pointee.range = 5
            }
        }
    }
}
