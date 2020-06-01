import XCTest
@testable import SparrowSafeBinaryCoder

final class SparrowSafeBinaryCoderTests: XCTestCase {
    struct Primitives: SafeBinaryCodable {
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
    
    func testExample() {
        let v = true
        let encoded = try? SafeBinaryEncoder.encode(v)
        
        print(encoded)
    }
    
    func testPrimitiveEncoding() throws {
        let s = Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: false, i: true, j: 8, k: 9)
        AssertRoundtrip(s)
    }
    
    func testBool() {
        let output = try! SafeBinaryEncoder.encode(true)
        XCTAssertEqual(output.count, 4) // nokeys, tag, size, value
        
        let input = try! SafeBinaryDecoder.decode(Bool.self, data: output)
        
        XCTAssertEqual(input, true)
    }
    
    func testFloat() {
        let output = try! SafeBinaryEncoder.encode(Float(10))
        XCTAssertEqual(output.count, 7) // nokeys, tag, size, value (4)
    }
    
    func testDouble() {
        let output = try! SafeBinaryEncoder.encode(Double(20))
        XCTAssertEqual(output.count, 11) // nokeys, tag, size, value (8)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

/// Assert equal without Equal protocol
private func AssertEqual<T>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(String(describing: lhs), String(describing: rhs), file: file, line: line)
}

private func AssertRoundtrip<T: SafeBinaryCodable>(_ original: T, file: StaticString = #file, line: UInt = #line) {
    do {
        let data = try SafeBinaryEncoder.encode(original)
        let roundtripped = try SafeBinaryDecoder.decode(T.self, data: data)
        AssertEqual(original, roundtripped, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}
