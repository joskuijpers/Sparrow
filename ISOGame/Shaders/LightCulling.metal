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
    float4 planes[6];
} TileFrustum;

/// Compute a tile frustum.
TileFrustum computeTileFrustum(
                               constant CameraUniforms &cameraUniforms,
                               uint2 groupId,
                               float tileMinZ,
                               float tileMaxZ,
                               uint2 outputSize
                               )
{
    TileFrustum frustum;
    
    
    float2 negativeStep = (2 * float2(groupId)) / float2(outputSize);
    float2 positiveStep = (2 * float2(groupId + uint2(1, 1))) / float2(outputSize);
    
    frustum.planes[0] = float4( 1, 0, 0, 1 - negativeStep.x); // Left
    frustum.planes[1] = float4(-1, 0, 0, -1 + positiveStep.x); // Right
    frustum.planes[2] = float4( 0, 1, 0, 1 - negativeStep.y); // Bottom
    frustum.planes[3] = float4( 0,-1, 0, -1 + positiveStep.y); // Top
    frustum.planes[4] = float4( 0, 0,-1, -tileMinZ); // Near
    frustum.planes[5] = float4( 0, 0, 1, tileMaxZ); // Far
    
    for (uint i = 0; i < 4; ++i) {
        frustum.planes[i] *= cameraUniforms.viewProjectionMatrix;
        frustum.planes[i] /= length(frustum.planes[i].xyz);
    }
    
    frustum.planes[4] *= cameraUniforms.viewMatrix;
    frustum.planes[4] /= length(frustum.planes[4].xyz);
    frustum.planes[5] *= cameraUniforms.viewMatrix;
    frustum.planes[5] /= length(frustum.planes[5].xyz);
    
//    float2 tileScale = float2(cameraUniforms.physicalSize) / float2(2 * LIGHT_CULLING_TILE_SIZE);
//
//    float2 tileMinScale = float2(tileMinZ) / float2(cameraUniforms.projectionMatrix[0][0], cameraUniforms.projectionMatrix[1][1]);
//    float2 tileMaxScale = float2(tileMaxZ) / float2(cameraUniforms.projectionMatrix[0][0], cameraUniforms.projectionMatrix[1][1]);
//
//    // Frustum corner positions
//    float2 frustumMinClipSpace = (1.0 - float2((int2)groupId.xy - 1) / tileScale.xy) * float2(-1.0, 1.0);
//    float2 frustumMaxClipSpace = (1.0 - float2((int2)groupId.xy + 1) / tileScale.xy) * float2(-1.0, 1.0);
//
    return frustum;
}

/// Get whether given light intersects the frustum.
bool intersectsFrustumTile(LightData light, float3 lightPosView, float range, TileFrustum frustum) {
    float dist = 0.0;
    
    for(int i = 0; i < 6; ++i) {
        float4 plane = frustum.planes[i];
        
        dist = dot(float4(lightPosView, 1), plane) + range;
        if (dist <= 0.0) {
            break;
        }
    }
    
    if (dist > 0.0) {
        return true;
    }
    
    return true;
}

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
                         
                         device uint16_t *culledLights [[ buffer(4) ]],
                         
                         depth2d<float, access::read> depthTexture [[texture(0)]]
                         )
{
    
    // Find min and max for this quad
    float4 zs;
    zs.x = depthTexture.read(coordinates * 2 + uint2(0, 0));
    zs.y = depthTexture.read(coordinates * 2 + uint2(1, 0));
    zs.z = depthTexture.read(coordinates * 2 + uint2(0, 1));
    zs.w = depthTexture.read(coordinates * 2 + uint2(1, 1));
    
    float4 depths;
    depths.x = dot(float2(zs.x, 1), cameraUniforms.invProjectionZ.xz) / dot(float2(zs.x, 1), cameraUniforms.invProjectionZ.yw);
    depths.y = dot(float2(zs.y, 1), cameraUniforms.invProjectionZ.xz) / dot(float2(zs.y, 1), cameraUniforms.invProjectionZ.yw);
    depths.z = dot(float2(zs.z, 1), cameraUniforms.invProjectionZ.xz) / dot(float2(zs.z, 1), cameraUniforms.invProjectionZ.yw);
    depths.w = dot(float2(zs.w, 1), cameraUniforms.invProjectionZ.xz) / dot(float2(zs.w, 1), cameraUniforms.invProjectionZ.yw);
    
    float4 minDepths = depths;
    minDepths.xy = min(minDepths.xy, minDepths.zw);
    float minDepth = min(minDepths.x, minDepths.y);
    
    float4 maxDepths = depths;
    maxDepths.xy = min(maxDepths.xy, maxDepths.zw);
    float maxDepth = min(maxDepths.x, maxDepths.y);
    
    // Tile-specific index of first light index in output list
    uint outputIdx = (groupId.x + groupId.y * outputSize.x) * MAX_LIGHTS_PER_TILE;
    
    threadgroup atomic_uint lightIndex;
    threadgroup atomic_uint atomicMinZ;
    threadgroup atomic_uint atomicMaxZ;
    
    atomic_store_explicit(&lightIndex, 0, metal::memory_order_relaxed);
    
    atomic_store_explicit(&atomicMinZ, 0x7F7FFFFF, metal::memory_order_relaxed);
    atomic_store_explicit(&atomicMaxZ, 0, metal::memory_order_relaxed);
    
    // Barrier to share the tile data state across all threads in the thread group.
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    // This will find the min and max for the whole threadgroup, as the variables are atomic.
    atomic_fetch_min_explicit(&atomicMinZ, as_type<uint>(minDepth), metal::memory_order_relaxed);
    atomic_fetch_min_explicit(&atomicMaxZ, as_type<uint>(maxDepth), metal::memory_order_relaxed);
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    
    float tileMinZ = as_type<float>(atomic_load_explicit(&atomicMinZ, metal::memory_order_relaxed));
    float tileMaxZ = as_type<float>(atomic_load_explicit(&atomicMaxZ, metal::memory_order_relaxed));
    
    TileFrustum frustum = computeTileFrustum(cameraUniforms, groupId, tileMinZ, tileMaxZ, outputSize);
    
    // Adjust pointer to output towards our own tile
    culledLights += outputIdx;
    
    // Culling is performed on multiple threads (not 1 per tile). So we split the number of lights
    // across the threads evenly by starting at the tread ID and skipping ThreadNum lights each time.
    for (uint i = threadId; i < lightsCount; i += blockDim.x * blockDim.y) {
        LightData lightData = lights[i];
        
        //// TODO this is PointLight specific. Add spotlights and directional lights (?)
        float3 lightPosView = lightData.position.xyz;
        float range = lightData.range;
        
        if (lightData.type != LightTypePoint) {
            continue;
        }
        //// END TODO
        
//        bool inFrustumMinZ = (lightPosView.z + range) > -frustum.tileMinZ;
//        bool inFrustumMaxZ = (lightPosView.z - range) < frustum.tileMaxZ;
//        bool inFrustumNearZ = (lightPosView.z + range) > 0; // near camera, for transparents
        
        // Quick culling of min/max Z
//        if (inFrustumMaxZ && inFrustumMinZ) {
            // Tile frustum culling
            bool visible = intersectsFrustumTile(lightData, lightPosView, range, frustum);
            if (visible) {
                // Fetch next position in the tile light list
                uint32_t index = atomic_fetch_add_explicit(&lightIndex, 1, metal::memory_order_relaxed);
                
                if (index + 1 < MAX_LIGHTS_PER_TILE) {
                    culledLights[index + 1] = i;
                }
            }
//        }
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    // Put number of lights in first element
    uint totalLights = atomic_load_explicit(&lightIndex, metal::memory_order_relaxed);
    culledLights[0] = min(totalLights, (uint)MAX_LIGHTS_PER_TILE - 1);
}

// Source: ModernRenderer. Has some special iOS optimizations
