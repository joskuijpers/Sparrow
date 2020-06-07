import XCTest
@testable import SparrowEngine2

final class SparrowEngine2Tests: XCTestCase {
    
    func testBounds() {
        let bounds = Bounds(center: [0, 1, 0], extents: [1, 1, 1])
        // -1, 0, -1   to   1, 2, 1
        
        XCTAssert(bounds.contains(point: [0, 1, 0]))
        XCTAssert(bounds.contains(point: [1, 1, 1]))
        XCTAssert(bounds.contains(point: [1, 2, 1]))
        XCTAssert(bounds.contains(point: [0, 0, 0]))
    }
    
    func testCameraShaderInfo() {
        let inf = CameraUniforms()
        
        print(inf)
    }

    static var allTests = [
        ("testBounds", testBounds),
    ]
}
