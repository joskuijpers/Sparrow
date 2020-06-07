import XCTest
@testable import SparrowEngine2

final class SparrowEngine2Tests: XCTestCase {
    
    func testCameraShaderInfo() {
        let inf = CameraUniforms()
        
        print(inf)
    }

    static var allTests = [
    ("testCameraShaderInfo", testCameraShaderInfo),
    ]
}
