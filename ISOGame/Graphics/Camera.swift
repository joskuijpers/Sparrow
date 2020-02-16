//
//  Camera.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Camera: Node {
    
    var fovDegrees: Float = 70
    var fovRadians: Float {
        return fovDegrees.degreesToRadians
    }
    var aspect: Float = 1
    var near: Float = 0.001
    var far: Float = 100
    
    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: fovRadians,
                        near: near,
                        far: far,
                        aspect: aspect)
    }
    
    var viewMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(rotation: rotation)
        let scaleMatrix = float4x4(scaling: scale)
        return (translateMatrix * scaleMatrix * rotateMatrix).inverse
    }
    
    func screenSizeWillChange(to size: CGSize) {
        aspect = Float(size.width / size.height)
    }
    
    func zoom(delta: Float) {}
    func rotate(delta: float2) {}
}

class PerspectiveCamera: Camera {
    // TODO move from parent
}

class OrthographicCamera: Camera {
    // TODO
}

class ArcballCamera: PerspectiveCamera {
  
  var minDistance: Float = 0.5
  var maxDistance: Float = 10
  var target: float3 = [0, 0, 0] {
    didSet {
      _viewMatrix = updateViewMatrix()
    }
  }
  
  var distance: Float = 0 {
    didSet {
      _viewMatrix = updateViewMatrix()
    }
  }
  
  override var rotation: float3 {
    didSet {
      _viewMatrix = updateViewMatrix()
    }
  }
  
  override var viewMatrix: float4x4 {
    return _viewMatrix
  }
  private var _viewMatrix = float4x4.identity()
  
  override init() {
    super.init()
    _viewMatrix = updateViewMatrix()
  }
  
  private func updateViewMatrix() -> float4x4 {
    let translateMatrix = float4x4(translation: [target.x, target.y, target.z - distance])
    let rotateMatrix = float4x4(rotationYXZ: [-rotation.x,
                                              rotation.y,
                                              0])
    let matrix = (rotateMatrix * translateMatrix).inverse
    position = rotateMatrix.upperLeft * -matrix.columns.3.xyz
    return matrix
  }
  
  override func zoom(delta: Float) {
    let sensitivity: Float = 0.05
    distance -= delta * sensitivity
    _viewMatrix = updateViewMatrix()
  }
  
  override func rotate(delta: float2) {
    let sensitivity: Float = 0.005
    rotation.y += delta.x * sensitivity
    rotation.x += delta.y * sensitivity
    rotation.x = max(-Float.pi/2,
                     min(rotation.x,
                         Float.pi/2))
    _viewMatrix = updateViewMatrix()
  }
}
