//
//  LightCulling.metal
//  ISOGame
//
//  Created by Jos Kuijpers on 22/03/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderCommon.h"

typedef struct {
    float minDepth;
    float maxDepth;
} CullTileData;

typedef struct {
    float4 planes[4];
} TileFrustum;

/// Convert a point from clip to view space
inline float4 clipToView(float4 in, constant CameraUniforms &cameraUniforms) {
    float4 view = cameraUniforms.invProjectionMatrix * in;
    view = view / view.w;
    
    return view;
}

/// Convert a point from screen to view space.
inline float4 screenToView(float4 in, constant CameraUniforms &cameraUniforms) {
    float2 texCoord = in.xy / cameraUniforms.physicalSize;
    float4 clip = float4(float2(texCoord.x, 1 - texCoord.y) * 2 - 1, in.z, in.w);
    
    return clipToView(clip, cameraUniforms);
}

/// Compute a plane using 3 vertices
float4 computeFrustumPlane(float3 p0, float3 p1, float3 p2) {
    float4 plane;
    
    float3 v0 = p1 - p0;
    float3 v2 = p2 - p0;
    
    plane.xyz = normalize(cross(v0, v2));
    plane.w = dot(plane.xyz, p0);
    
    return plane;
}

/// Compute a tile frustum.
TileFrustum computeTileFrustum(
                               constant CameraUniforms &cameraUniforms,
                               uint2 groupId
                               )
{
    TileFrustum frustum;
    const float3 eyePos = float3(0, 0, 0);
    float4 screenSpace[4];
    float3 viewSpace[4];
    
    // https://www.3dgep.com/forward-plus/#Grid_Frustums_Compute_Shader
    // Compute 4 corner points on the far clipping plane
    screenSpace[0] = float4(float2((groupId + uint2(0, 0)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    screenSpace[1] = float4(float2((groupId + uint2(1, 0)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    screenSpace[2] = float4(float2((groupId + uint2(0, 1)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    screenSpace[3] = float4(float2((groupId + uint2(1, 1)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    
    // Convert screen space to view space
    
    for (int i = 0; i < 4; ++i) {
        viewSpace[i] = screenToView(screenSpace[i], cameraUniforms).xyz;
    }
    
    // Build frustum planes
    frustum.planes[0] = computeFrustumPlane(eyePos, viewSpace[2], viewSpace[0]);
    frustum.planes[1] = computeFrustumPlane(eyePos, viewSpace[1], viewSpace[3]);
    frustum.planes[2] = computeFrustumPlane(eyePos, viewSpace[0], viewSpace[1]);
    frustum.planes[3] = computeFrustumPlane(eyePos, viewSpace[3], viewSpace[2]);
    
    return frustum;
}

bool sphereInsidePlane(float3 position, float radius, float4 plane) {
    return dot(plane.xyz, position) - plane.w < -radius;
}

bool sphereInsideFrustum(float3 position, float radius, TileFrustum frustum, float zNear, float zFar) {
    bool result = true;
    
    if (position.z + radius < zNear || position.z - radius > zFar) {
        result = false;
    }
    
    for (int i = 0; i < 4 && result; ++i) {
        if (sphereInsidePlane(position, radius, frustum.planes[i])) {
            result = false;
        }
    }
    
    return result;
}

// Converts a depth from the depth buffer into a view space depth.
inline float linearizeDepth(constant CameraUniforms &cameraUniforms, float depth) {
    return dot(float2(depth, 1), cameraUniforms.invProjectionZ.xz) / dot(float2(depth, 1), cameraUniforms.invProjectionZ.yw);
}

inline float4 getHeatmapColor(uint x, uint num);

kernel void lightculling(
                         uint2 coordinates        [[thread_position_in_grid]],
                         uint threadId            [[thread_index_in_threadgroup]],
                         uint2 groupId            [[threadgroup_position_in_grid]],
                         uint2 outputSize         [[threadgroups_per_grid]],
                         uint2 blockDim           [[threads_per_threadgroup]],
                         uint quadLaneId          [[thread_index_in_quadgroup]],

                         constant CameraUniforms &cameraUniforms [[ buffer(1) ]],
                         
                         constant LightData *lights [[ buffer(2) ]],
                         constant uint &lightsCount [[ buffer(3) ]],
                         
                         device uint16_t *culledLightsOpaque [[ buffer(4) ]],
                         device uint16_t *culledLightsTransparent [[ buffer(5) ]],
                         
                         depth2d<float, access::read> depthTexture [[texture(0)]],
                         texture2d<float, access::write> debugTexture [[texture(1)]]
                         )
{
    if (any(coordinates >= uint2(depthTexture.get_width(), depthTexture.get_height()))) {
        return;
    }
    
    // Depth of the pixel this thread covers
    float depth = linearizeDepth(cameraUniforms, depthTexture.read(coordinates));
    
    // Tile-specific index of first light index in output list
    uint outputIdx = (groupId.x + groupId.y * outputSize.x) * MAX_LIGHTS_PER_TILE;
    
    threadgroup atomic_uint lightIndexOpaque;
    threadgroup atomic_uint lightIndexTransparent;
    threadgroup atomic_uint atomicMinZ;
    threadgroup atomic_uint atomicMaxZ;
    
    atomic_store_explicit(&lightIndexOpaque, 0, metal::memory_order_relaxed);
    atomic_store_explicit(&lightIndexTransparent, 0, metal::memory_order_relaxed);
    
    atomic_store_explicit(&atomicMinZ, 0x7F7FFFFF, metal::memory_order_relaxed);
    atomic_store_explicit(&atomicMaxZ, 0, metal::memory_order_relaxed);
    
    // Barrier to share the tile data state across all threads in the thread group.
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    // This will find the min and max for the whole threadgroup, as the variables are atomic.
    atomic_fetch_min_explicit(&atomicMinZ, as_type<uint>(depth), metal::memory_order_relaxed);
    atomic_fetch_max_explicit(&atomicMaxZ, as_type<uint>(depth), metal::memory_order_relaxed);
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    float tileMinZ = as_type<float>(atomic_load_explicit(&atomicMinZ, metal::memory_order_relaxed));
    float tileMaxZ = as_type<float>(atomic_load_explicit(&atomicMaxZ, metal::memory_order_relaxed));
    
    // Create the near clip plane
    float nearClipVS = clipToView(float4(0, 0, 0, 1), cameraUniforms).z;
    
    // Clipping plane for minimum depth value.
    float4 minPlane = float4(0, 0, 1, tileMinZ);
    
    TileFrustum frustum = computeTileFrustum(cameraUniforms, groupId);
    
    // Adjust pointer to output towards our own tile
    culledLightsOpaque += outputIdx;
    culledLightsTransparent += outputIdx;
    
    // Culling is performed on multiple threads (not 1 per tile). So we split the number of lights
    // across the threads evenly by starting at the tread ID and skipping ThreadNum lights each time.
    for (uint i = threadId; i < lightsCount; i += blockDim.x * blockDim.y) {
        LightData lightData = lights[i];
        
        switch (lightData.type) {
            case LightTypePoint: {
                float4 vsPosition = cameraUniforms.viewMatrix * lightData.position;
                
                if (sphereInsideFrustum(vsPosition.xyz, lightData.range, frustum, nearClipVS, tileMaxZ)) {
                    // Fetch next position in the tile light list
                    uint32_t index = atomic_fetch_add_explicit(&lightIndexTransparent, 1, metal::memory_order_relaxed);
                    if (index + 1 < MAX_LIGHTS_PER_TILE) {
                        culledLightsTransparent[index + 1] = i;
                    }

                    if (!sphereInsidePlane(vsPosition.xyz, lightData.range, minPlane)) {
                        uint32_t index = atomic_fetch_add_explicit(&lightIndexOpaque, 1, metal::memory_order_relaxed);
                        if (index + 1 < MAX_LIGHTS_PER_TILE) {
                            culledLightsOpaque[index + 1] = i;
                        }
                    }
                }
                
                break;
            }
            case LightTypeDirectional: {
                uint32_t index = atomic_fetch_add_explicit(&lightIndexTransparent, 1, metal::memory_order_relaxed);
                if (index + 1 < MAX_LIGHTS_PER_TILE) {
                    culledLightsTransparent[index + 1] = i;
                }
                
                index = atomic_fetch_add_explicit(&lightIndexOpaque, 1, metal::memory_order_relaxed);
                if (index + 1 < MAX_LIGHTS_PER_TILE) {
                    culledLightsOpaque[index + 1] = i;
                }
            }
            default: break;
        }
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    // Put number of lights in first element
    uint totalLightsOpaque = atomic_load_explicit(&lightIndexOpaque, metal::memory_order_relaxed);
    culledLightsOpaque[0] = min(totalLightsOpaque, (uint)MAX_LIGHTS_PER_TILE - 1);
    
    uint totalLightsTransparent = atomic_load_explicit(&lightIndexTransparent, metal::memory_order_relaxed);
    culledLightsTransparent[0] = min(totalLightsTransparent, (uint)MAX_LIGHTS_PER_TILE - 1);
    
//    if (coordinates.x == 0 && coordinates.y == 0) {
//        debugTexture.write(float4(totalLightsOpaque - 1, 0, 0, 1), coordinates);
//    }
    
    debugTexture.write(float4(1-(depth / 100.f), tileMinZ / 50.f, tileMaxZ / 50.0f, (float)totalLightsOpaque / (float)MAX_LIGHTS_PER_TILE), coordinates);
}

// Source: ModernRenderer. Has some special iOS optimizations
