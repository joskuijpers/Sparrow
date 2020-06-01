# SparrowEngine2

The Sparrow Game Engine





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
