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
    float3 normal;
    float dist;
} TileFrustumPlane;

typedef struct {
    TileFrustumPlane planes[4];
} TileFrustum;


typedef struct {
    float3 center;
    float3 extents;
    
    inline float3 getMin() { return center - extents; }
    inline float3 getMax() { return center + extents; }
} AABB;

typedef struct {
    float3 center;
    float radius;
} Sphere;

/// Convert a point from clip to view space
inline float4 clipToView(float4 clip, constant CameraUniforms &cameraUniforms) {
    // View space position
    float4 view = cameraUniforms.invProjectionMatrix * clip;
    
    // Perspective projection
    view = view / view.w;
    
    return view;
}

/// Convert a point from screen to view space.
inline float4 screenToView(float4 screen, constant CameraUniforms &cameraUniforms) {
    float2 texCoord = screen.xy / cameraUniforms.physicalSize;
    float4 clip = float4(float2(texCoord.x, 1.f - texCoord.y) * 2.f - 1.f, screen.z, screen.w);
    
    return clipToView(clip, cameraUniforms);
}

/// Compute a plane using 3 vertices
TileFrustumPlane computeFrustumPlane(float3 p0, float3 p1, float3 p2) {
    TileFrustumPlane plane;
    
    float3 v0 = p1 - p0;
    float3 v2 = p2 - p0;
    
    plane.normal = normalize(cross(v0, v2));
    
    // Distance to the origin
    plane.dist = dot(plane.normal, p0);
    
    return plane;
}

/// Compute a tile frustum.
TileFrustum computeTileFrustum(
                               constant CameraUniforms &cameraUniforms,
                               uint2 groupId
                               )
{
    const float3 eyePos = float3(0, 0, 0);
    
    // https://www.3dgep.com/forward-plus/#Grid_Frustums_Compute_Shader
    // Compute 4 corner points on the far clipping plane
    float4 screenSpace[4];
    screenSpace[0] = float4(float2((groupId + uint2(0, 0)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    screenSpace[1] = float4(float2((groupId + uint2(1, 0)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    screenSpace[2] = float4(float2((groupId + uint2(0, 1)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    screenSpace[3] = float4(float2((groupId + uint2(1, 1)) * LIGHT_CULLING_TILE_SIZE), 1, 1);
    
    // Convert screen space to view space
    float3 viewSpace[4];
    for (int i = 0; i < 4; ++i) {
        viewSpace[i] = screenToView(screenSpace[i], cameraUniforms).xyz;
    }
    
    // Build frustum planes
    TileFrustum frustum;
    frustum.planes[0] = computeFrustumPlane(viewSpace[2], eyePos, viewSpace[0]);
    frustum.planes[1] = computeFrustumPlane(viewSpace[1], eyePos, viewSpace[3]);
    frustum.planes[2] = computeFrustumPlane(viewSpace[0], eyePos, viewSpace[1]);
    frustum.planes[3] = computeFrustumPlane(viewSpace[3], eyePos, viewSpace[2]);
    
    return frustum;
}

bool sphereInsidePlane(Sphere sphere, TileFrustumPlane plane) {
    return dot(plane.normal, sphere.center) - plane.dist < -sphere.radius;
}

bool sphereInsideFrustum(Sphere sphere, TileFrustum frustum, float zNear, float zFar) {
    bool result = true;
    
//    if (position.z + radius < zNear || position.z - radius > zFar) {
//        result = false;
//    }
//
//    for (int i = 0; i < 4 && result; ++i) {
//        if (sphereInsidePlane(position, radius, frustum.planes[i])) {
//            result = false;
//        }
//    }
    
    // Unrolling is better
    result = ((sphere.center.z + sphere.radius < zNear || sphere.center.z - sphere.radius > zFar) ? false : result);
    result = ((sphereInsidePlane(sphere, frustum.planes[0])) ? false : result);
    result = ((sphereInsidePlane(sphere, frustum.planes[1])) ? false : result);
    result = ((sphereInsidePlane(sphere, frustum.planes[2])) ? false : result);
    result = ((sphereInsidePlane(sphere, frustum.planes[3])) ? false : result);
    
    return result;
}

bool sphereIntersectsAABB(float3 center, float range, AABB aabb)
{
    float3 vDelta = max(0, abs(aabb.center - center) - aabb.extents);
    float fDistSq = dot(vDelta, vDelta);
    return fDistSq <= range * range;
}

bool intersectAABB(AABB a, AABB b)
{
    if (abs(a.center[0] - b.center[0]) > (a.extents[0] + b.extents[0]))
        return false;
    if (abs(a.center[1] - b.center[1]) > (a.extents[1] + b.extents[1]))
        return false;
    if (abs(a.center[2] - b.center[2]) > (a.extents[2] + b.extents[2]))
        return false;

    return true;
}

AABB computeAABB(
                 constant CameraUniforms &cameraUniforms,
                 uint2 groupId,
                 float minDepth,
                 float maxDepth
                 ) {
    AABB aabb;

    float3 viewSpace[8];

    // Top left point, near
    viewSpace[0] = screenToView(float4(float2(groupId.xy) * LIGHT_CULLING_TILE_SIZE, minDepth, 1.0f), cameraUniforms).xyz;
    // Top right point, near
    viewSpace[1] = screenToView(float4(float2(groupId.x + 1, groupId.y) * LIGHT_CULLING_TILE_SIZE, minDepth, 1.0f), cameraUniforms).xyz;
    // Bottom left point, near
    viewSpace[2] = screenToView(float4(float2(groupId.x, groupId.y + 1) * LIGHT_CULLING_TILE_SIZE, minDepth, 1.0f), cameraUniforms).xyz;
    // Bottom right point, near
    viewSpace[3] = screenToView(float4(float2(groupId.x + 1, groupId.y + 1) * LIGHT_CULLING_TILE_SIZE, minDepth, 1.0f), cameraUniforms).xyz;

    // Top left point, far
    viewSpace[4] = screenToView(float4(float2(groupId.xy) * LIGHT_CULLING_TILE_SIZE, maxDepth, 1.0f), cameraUniforms).xyz;
    // Top right point, far
    viewSpace[5] = screenToView(float4(float2(groupId.x + 1, groupId.y) * LIGHT_CULLING_TILE_SIZE, maxDepth, 1.0f), cameraUniforms).xyz;
    // Bottom left point, far
    viewSpace[6] = screenToView(float4(float2(groupId.x, groupId.y + 1) * LIGHT_CULLING_TILE_SIZE, maxDepth, 1.0f), cameraUniforms).xyz;
    // Bottom right point, far
    viewSpace[7] = screenToView(float4(float2(groupId.x + 1, groupId.y + 1) * LIGHT_CULLING_TILE_SIZE, maxDepth, 1.0f), cameraUniforms).xyz;

    float3 minAABB = 10000000;
    float3 maxAABB = -10000000;

    for (uint i = 0; i < 8; ++i)
    {
        minAABB = min(minAABB, viewSpace[i]);
        maxAABB = max(maxAABB, viewSpace[i]);
    }

    aabb.center = (minAABB + maxAABB) * 0.5f;
    aabb.extents = abs(maxAABB - aabb.center);

    // We can perform coarse AABB intersection tests with this:
//    GroupAABB_WS = GroupAABB;
//    AABBtransform(GroupAABB_WS, g_xCamera_InvV);
    
    return aabb;
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

                         constant CameraUniforms &cameraUniforms [[ buffer(1) ]],
                         
                         constant LightData *lights [[ buffer(2) ]],
                         constant uint &lightsCount [[ buffer(3) ]],
                         
                         device uint16_t *culledLightsOpaque [[ buffer(4) ]],
                         device uint16_t *culledLightsTransparent [[ buffer(5) ]],
                         
                         depth2d<float, access::read> depthTexture [[texture(0)]]
                         )
{
    if (any(coordinates >= uint2(depthTexture.get_width(), depthTexture.get_height()))) {
        return;
    }
    
    // Depth of the pixel this thread covers
    float depth = depthTexture.read(coordinates);
    
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
    
    float minDepthVS = clipToView(float4(0, 0, tileMinZ, 1), cameraUniforms).z;
    float maxDepthVS = clipToView(float4(0, 0, tileMaxZ, 1), cameraUniforms).z;
    float nearClipVS = clipToView(float4(0, 0, 0, 1), cameraUniforms).z;
    
    // Clipping plane for minimum depth value.
    TileFrustumPlane minPlane = { float3(0, 0, 1), minDepthVS };
    
    TileFrustum frustum = computeTileFrustum(cameraUniforms, groupId);
    
    // Adjust pointer to output towards our own tile
    culledLightsOpaque += outputIdx;
    culledLightsTransparent += outputIdx;
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    // Culling is performed on multiple threads (not 1 per tile). So we split the number of lights
    // across the threads evenly by starting at the tread ID and skipping ThreadNum lights each time.
    for (uint i = threadId; i < lightsCount; i += blockDim.x * blockDim.y) {
        LightData lightData = lights[i];
        
        switch (lightData.type) {
            case LightTypePoint: {
                float4 vsPosition = cameraUniforms.viewMatrix * float4(lightData.position, 1);
                Sphere sphere = { vsPosition.xyz, lightData.range };
                
                if (sphereInsideFrustum(sphere, frustum, nearClipVS, maxDepthVS)) {
                    // Fetch next position in the tile light list
                    uint32_t index = atomic_fetch_add_explicit(&lightIndexTransparent, 1, metal::memory_order_relaxed);
                    if (index + 1 < MAX_LIGHTS_PER_TILE) {
                        culledLightsTransparent[index + 1] = i;
                    }

//                    if (sphereIntersectsAABB(vsPosition.xyz, lightData.range, aabb)) {
                    if (!sphereInsidePlane(sphere, minPlane)) {
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
                
                break;
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
}

// Source: ModernRenderer. Has some special iOS optimizations
