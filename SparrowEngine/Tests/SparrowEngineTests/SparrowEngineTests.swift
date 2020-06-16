import XCTest
@testable import SparrowEngine

final class SparrowEngineTests: XCTestCase {
    
    func testCameraShaderInfo() {
        let inf = CameraUniforms()
        
        print(inf)
    }

    static var allTests = [
        ("testCameraShaderInfo", testCameraShaderInfo),
    ]
}
