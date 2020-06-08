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
    let lights: Group<Requires2<Transform, Light>>
    let device: MTLDevice
    
    public init(nexus: Nexus, device: MTLDevice) {
        lights = nexus.group(requiresAll: Transform.self, Light.self)
        self.device = device
    }
    
    public func updateLightBuffer(buffer: MTLBuffer!, lightsCount: inout UInt) -> MTLBuffer {
        var buffer = buffer
        
        lightsCount = UInt(lights.count)
        
        // Reallocate if needed
        // TODO: proper sizing with spare-size (blocks), and down sizing. Maybe some ManagedMTLBuffer class?
        let bufferSizeRequired = lights.count * MemoryLayout<ShaderLightData>.stride
        if buffer == nil || buffer!.allocatedSize < bufferSizeRequired {
            buffer = device.makeBuffer(length: bufferSizeRequired, options: .storageModeShared)
        }

        for (index, (transform, light)) in lights.enumerated() {
            let ptr = buffer!.contents().advanced(by: index * MemoryLayout<ShaderLightData>.stride)
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
        
        return buffer!
    }
}
