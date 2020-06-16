import XCTest
@testable import SparrowEngine

final class BoundsTests: XCTestCase {
    
    func testIsEmpty() {
        XCTAssertEqual(Bounds(center: .zero, extents: .zero).isEmpty, true)
        XCTAssertEqual(Bounds(center: .zero, extents: .one).isEmpty, false)
    }
    
    func testSize() {
        XCTAssertEqual(Bounds(center: .zero, extents: .zero).size, float3(0,0,0))
        XCTAssertEqual(Bounds(center: .zero, extents: .one).size, float3(2,2,2))
    }
    
    func testCenter() {
        XCTAssertEqual(Bounds(minBounds: .zero, maxBounds: .one).center, float3(0.5, 0.5, 0.5))
    }
    
    func testContains() {
        let bounds = Bounds(center: [0, 1, 0], extents: [1, 1, 1])
        // -1, 0, -1   to   1, 2, 1

        XCTAssert(bounds.contains(point: [0, 1, 0]))
        XCTAssert(bounds.contains(point: [1, 1, 1]))
        XCTAssert(bounds.contains(point: [1, 2, 1]))
        XCTAssert(bounds.contains(point: [0, 0, 0]))
        XCTAssert(!bounds.contains(point: [0, 10, 0]))
        XCTAssert(!bounds.contains(point: [-1, 10, 0]))
        XCTAssert(!bounds.contains(point: [-1, -1, -1]))
        XCTAssert(!bounds.contains(point: [-1, -1, 1]))
    }
    
    func testClosest() {
        let bounds = Bounds(center: [0, 0, 0], extents: [1, 1, 1])
        
        XCTAssertEqual(bounds.closest(point: [0,0,0]), [0,0,0])
        XCTAssertEqual(bounds.closest(point: [1,1,1]), [1,1,1])
        XCTAssertEqual(bounds.closest(point: [2,2,2]), [1,1,1])
        XCTAssertEqual(bounds.closest(point: [2,0,2]), [1,0,1])
    }
    
    func testIntersects() {
        let bounds = Bounds(center: [0, 0, 0], extents: [1, 1, 1])
        
        XCTAssert(bounds.intersects(bounds: Bounds(center: [0, 0, 0], extents: [1, 1, 1]))) // equal
        XCTAssert(bounds.intersects(bounds: Bounds(center: [0.5, 0.5, 0.5], extents: [1, 1, 1]))) // partial
        XCTAssert(bounds.intersects(bounds: Bounds(center: [0.5, 0.5, 0.5], extents: [0.2, 0.2, 0.2]))) // inside
        XCTAssert(bounds.intersects(bounds: Bounds(center: [2, 2, 2], extents: [1, 1, 1]))) // adjacent with 1 point
        
        XCTAssert(!bounds.intersects(bounds: Bounds(center: [3, 3, 3], extents: [1, 1, 1]))) // away
        XCTAssert(bounds.intersects(bounds: Bounds(center: [0, 2, 0], extents: [1, 1, 1]))) // next to each other
        XCTAssert(!bounds.intersects(bounds: Bounds(center: [0, 2.001, 0], extents: [1, 1, 1]))) // next to each other with spacing
    }
    
    func testEncapsulate() {
        let b1 = Bounds(center: .zero, extents: .one)
        let b2 = Bounds(center: .one, extents: .one)
        let b3 = Bounds(center: [0.5, 0.5, 0.5], extents: [1.5, 1.5, 1.5])
        
        let e = b1.encapsulate(b2)
        XCTAssertEqual(e.center, b3.center)
        XCTAssertEqual(e.extents, b3.extents)
        
        XCTAssertEqual(b3, e)
    }

    static var allTests = [
    ("testContains", testContains),
    ("testClosest", testClosest),
    ("testIntersects", testIntersects),
    ]
}
