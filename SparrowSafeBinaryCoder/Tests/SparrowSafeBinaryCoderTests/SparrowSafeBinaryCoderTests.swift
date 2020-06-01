import XCTest
@testable import SparrowSafeBinaryCoder

final class SparrowSafeBinaryCoderTests: XCTestCase {
    struct Primitives: Codable, Equatable {
        var a: Int8
        var b: UInt16
        var c: Int32
        var d: UInt64
        var e: Int
        var f: Float
        var g: Double
        var h: Bool
        var i: Bool
        var j: Int64
        var k: UInt
    }
    
    struct Safeness1: Codable, Equatable {
        let a: Int8
        let b: UInt16
    }
    
    struct Safeness2: Codable, Equatable {
        let b: UInt16
    }
    
    struct Safeness3: Codable, Equatable {
        let a: Int8
        let b: UInt16
        var c: Int32?
    }
    
    func testPrimitiveRoundtrip() throws {
        let s = Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: false, i: true, j: 8, k: 9)
        AssertRoundtrip(s)
    }
    
    // Test that removing an attribute still loads
    func testPrimitiveSafeness() throws {
        let s = Safeness1(a: 1, b: 2)
        let s2 = Safeness2(b: 2)
        
        let data = try SafeBinaryEncoder.encode(s)
        let part2 = try SafeBinaryDecoder.decode(Safeness2.self, data: data)
        
        XCTAssertEqual(part2, s2)
    }
    
    // Test that removing an attribute still loads
    func testPrimitiveSafenessNewItem() throws {
        let s = Safeness1(a: 1, b: 3)
        let s3 = Safeness3(a: 1, b: 3, c: nil)
        
        let data = try SafeBinaryEncoder.encode(s)
        let part3 = try SafeBinaryDecoder.decode(Safeness3.self, data: data)
        
        XCTAssertEqual(part3, s3)
    }
    
    func testBool() {
        AssertRoundtrip(true)
        AssertRoundtrip(false)
    }
    
    func testFloat() {
        AssertRoundtrip(Float(10))
    }
    
    func testDouble() {
        AssertRoundtrip(Double(20))
    }

    static var allTests = [
        ("testPrimitiveRoundtrip", testPrimitiveRoundtrip),
        ("testPrimitiveSafeness", testPrimitiveSafeness),
        ("testPrimitiveSafenessNewItem", testPrimitiveSafenessNewItem),
        ("testBool", testBool),
        ("testFloat", testFloat),
        ("testDouble", testDouble),
    ]
}

/// Assert equal without Equal protocol
private func AssertEqual<T>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(String(describing: lhs), String(describing: rhs), file: file, line: line)
}

private func AssertRoundtrip<T: Codable>(_ original: T, file: StaticString = #file, line: UInt = #line) {
    do {
        let data = try SafeBinaryEncoder.encode(original)
        let roundtripped = try SafeBinaryDecoder.decode(T.self, data: data)
        AssertEqual(original, roundtripped, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}
