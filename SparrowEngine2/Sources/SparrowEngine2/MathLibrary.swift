//
//  MathLibrary.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import simd

/// A vector of two floating point scalars.
public typealias float2 = SIMD2<Float>

/// A vector of three floating point scalars.
public typealias float3 = SIMD3<Float>

/// A vector of four floating point scalars.
public typealias float4 = SIMD4<Float>

/// A vector of two 32-bit signed integer scalars.
public typealias int2 = SIMD2<Int32>

/// A vector of two 32-bit unsigned integer scalars.
public typealias uint2 = SIMD2<UInt32>

/// The mathematical constant pi.
public let π = Float.pi

extension Float {
    /// Get the degrees of a value assumed to be a radian angle.
    var radiansToDegrees: Float {
        (self / π) * 180
    }
    
    /// Get the radians of a value assumed to be a degree angle.
    var degreesToRadians: Float {
        (self / 180) * π
    }
}


// MARK:- float4
extension float4x4 {
    /// An affine matrix that translates vectors.
    @inlinable
    init(translation: float3) {
        self = float4x4(
            [            1,             0,             0, 0],
            [            0,             1,             0, 0],
            [            0,             0,             1, 0],
            [translation.x, translation.y, translation.z, 1]
        )
    }
    
    /// An affine transform matrix that scales vectors.
    @inlinable
    init(scaling: float3) {
        self = float4x4(
            [scaling.x,         0,         0, 0],
            [        0, scaling.y,         0, 0],
            [        0,         0, scaling.z, 0],
            [        0,         0,         0, 1]
        )
    }
    
    /// An affine matrix that scales vectors uniformly.
    @inlinable
    init(scaling: Float) {
        self = matrix_identity_float4x4
        columns.3.w = 1 / scaling
    }
    
    /// A matrix that rotates a vector over the X axis a given amount of radians.
    @inlinable
    init(rotationX angle: Float) {
        self = float4x4(
            [1,           0,          0, 0],
            [0,  cos(angle), sin(angle), 0],
            [0, -sin(angle), cos(angle), 0],
            [0,           0,          0, 1]
        )
    }
    
    /// A matrix that rotates a vector over the Y axis a given amount of radians.
    @inlinable
    init(rotationY angle: Float) {
        self = float4x4(
            [cos(angle), 0, -sin(angle), 0],
            [         0, 1,           0, 0],
            [sin(angle), 0,  cos(angle), 0],
            [         0, 0,           0, 1]
        )
    }
    
    /// A matrix that rotates a vector over the Z axis a given amount of radians.
    @inlinable
    init(rotationZ angle: Float) {
        self = float4x4(
            [ cos(angle), sin(angle), 0, 0],
            [-sin(angle), cos(angle), 0, 0],
            [          0,          0, 1, 0],
            [          0,          0, 0, 1]
        )
    }
    
    /// A matrix that rotates a vector over each axis with given radians for each.
    @inlinable
    init(rotation angle: float3) {
        let x = angle.x
        let y = angle.y
        let z = angle.z
        
        self = float4x4(
            [cos(z) * cos(y), sin(z) * cos(y), -sin(y), 0],
            [cos(z) * sin(y) * sin(x) - sin(z) * cos(x), sin(z) * sin(y) * sin(x) + cos(z) * cos(x), cos(y) * sin(x), 0],
            [cos(z) * sin(y) * cos(x) + sin(z) * sin(x), sin(z) * sin(y) * sin(x) - cos(z) * sin(x), cos(y) * cos(x), 0],
            [0, 0, 0, 1]
        )
    }
    
    @inlinable
    init(rotationYXZ angle: float3) {
        let rotationX = float4x4(rotationX: angle.x)
        let rotationY = float4x4(rotationY: angle.y)
        let rotationZ = float4x4(rotationZ: angle.z)
        self = rotationY * rotationX * rotationZ
    }
    
    /// The identitiy matrix
    @inlinable
    static func identity() -> float4x4 {
        matrix_identity_float4x4
    }
    
    /// The upper left 3x3 matrix (ignoring w in all directions)
    @inlinable
    var upperLeft: float3x3 {
        let x = columns.0.xyz
        let y = columns.1.xyz
        let z = columns.2.xyz
        return float3x3(columns: (x, y, z))
    }
    
    /// Left-handed LookAt matrix
    init(eye: float3, center: float3, up: float3) {
        let z = normalize(center-eye)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        
        let X = float4(x.x, y.x, z.x, 0)
        let Y = float4(x.y, y.y, z.y, 0)
        let Z = float4(x.z, y.z, z.z, 0)
        let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
        
        self.init()
        columns = (X, Y, Z, W)
    }
    
    /// Left handed perspective matrix.
    init(perspectiveAspect aspect: Float, fovy: Float, near: Float, far: Float) {
        // https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixperspectivelh?redirectedfrom=MSDN
        
        self.init()
        
        let yScale = 1 / tanf(fovy * 0.5)
        let xScale = yScale / aspect
        let zScale =  far / (far - near)
        let wzScale = near * far / (near - far)
        
        self = float4x4(float4(xScale, 0, 0, 0),
                        float4(0, yScale, 0, 0),
                        float4(0, 0, zScale, 1),
                        float4(0, 0, wzScale, 0))
    }
    
    /// Left handed orthographic matrix.
    init(orthoLeft left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
        let X = float4(2 / (right - left), 0, 0, 0)
        let Y = float4(0, 2 / (top - bottom), 0, 0)
        let Z = float4(0, 0, 1 / (far - near), 0)
        let W = float4((left + right) / (left - right),
                       (top + bottom) / (bottom - top),
                       near / (near - far),
                       1)
        self.init()
        columns = (X, Y, Z, W)
    }
    
    /// Create a matrix from a double4x4 matrix.
    init(_ m: matrix_double4x4) {
        self.init()
        let matrix: float4x4 = float4x4(float4(m.columns.0),
                                        float4(m.columns.1),
                                        float4(m.columns.2),
                                        float4(m.columns.3))
        self = matrix
    }
}

// MARK:- float3 Utilities
extension float3 {
    /// Forward vector: positive Z
    @inlinable
    var forward: float3 {
        return float3(0, 0, 1)
    }
    
    /// Up vector: positive Y.
    @inlinable
    var up: float3 {
        return float3(0, 1, 0)
    }
    
    /// Right vector: positive X.
    @inlinable
    var right: float3 {
        return float3(1, 0, 0)
    }
}

// MARK:- float4
extension float4 {
    /// XYZ components as a float3.
    @inlinable
    var xyz: float3 {
        get {
            float3(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    /// Convert a vector with double scalars to float scalars.
    ///
    /// Might cause loss of precision.
    init(_ d: SIMD4<Double>) {
        self.init()
        self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
    }
}
