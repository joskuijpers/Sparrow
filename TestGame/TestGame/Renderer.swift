
/*
 
 MESH RENDERING
 
 FunctionConstants gTransparent, gUseAlphaMask
 
 // Default vertex type.
 struct AAPLVertex
 {
     float3 position     [[attribute(AAPLVertexAttributePosition)]];
     xhalf3 normal       [[attribute(AAPLVertexAttributeNormal)]];
     xhalf3 tangent      [[attribute(AAPLVertexAttributeTangent)]];
     float2 texCoord     [[attribute(AAPLVertexAttributeTexcoord)]];
 };

 // Output from the main rendering vertex shader.
 struct AAPLVertexOutput
 {
     float4 position [[position]];
     float4 frozenPosition;
     xhalf3 viewDir;
     xhalf3 normal;
     xhalf3 tangent;
     float2 texCoord;
     float3 wsPosition;
 };
 
 struct AAPLDepthOnlyVertex
 {
     float3 position [[attribute(AAPLVertexAttributePosition)]];
 };

 // Depth only vertex output type.
 struct AAPLDepthOnlyVertexOutput
 {
     float4 position [[position]];
 };
 
 
 
 // Depth only vertex type with texcoord for alpha mask.
 struct AAPLDepthOnlyAlphaMaskVertex
 {
     float3 position [[attribute(AAPLVertexAttributePosition)]];
     float2 texCoord [[attribute(AAPLVertexAttributeTexcoord)]];
 };

 // Depth only vertex output type with texcoord for alpha mask.
 struct AAPLDepthOnlyAlphaMaskVertexOutput
 {
     float4 position [[position]];
     float2 texCoord;
 };
 
 
 
 // Converts a depth from the depth buffer into a view space depth.
 inline float linearizeDepth(constant AAPLCameraUniforms & cameraUniforms, float depth)
 {
     return dot(float2(depth,1), cameraUniforms.invProjZ.xz) / dot(float2(depth,1), cameraUniforms.invProjZ.yw);
 }
 
 
 getPixelSurfaceData(vertexOut, material) -> SurfaceData
 
 
 
 vertex shader: depth only(in, cameraUniforms) -> viewProj matrix on position
 
 
 fragment shader: depth only -> none
 
 vertex shader: depthonly + alpha(in, cameraUniforms) -> viewproj matrix on position, tex
 fragment shader: depthonly + alpga -> cutout -> sample albedo,, compare alpha to cutout for the material, discard
 
 
 SurfaceData {
 normal, albedo, f0, occlusion, emissive, metalness, roughness, alpha
 }
 
 
 Uniforms
    time
 CameraUniforms
 
 GlobalTextures
    depth2d_array<float>    shadowMap           [[ id(AAPLGlobalTextureIndexShadowMap) ]];
    texturecube<xhalf>      envMap              [[ id(AAPLGlobalTextureIndexEnvMap) ]];
    texture2d<float, access::read>  blueNoise   [[ id(AAPLGlobalTextureIndexBlueNoise) ]];
    texture3d<float, access::read>  perlinNoise [[ id(AAPLGlobalTextureIndexPerlinNoise) ]];
    texture2d<xhalf, access::read> ssao
 
 
 */
